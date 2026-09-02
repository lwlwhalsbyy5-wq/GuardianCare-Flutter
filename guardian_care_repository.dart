import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'guardian_care_store.dart';

// ── Configure your XAMPP IP here (one place, used by the whole repo) ──
const String kApiBase = 'http://localhost/guardian_backend/api.php';
// Android emulator  → 10.0.2.2
// Real device       → your PC's LAN IP, e.g. 192.168.1.100
// iOS simulator     → 127.0.0.1

abstract class GuardianCareRepository {
  ValueListenable<int> get versionListenable;

  String normalizeUserId(String value);

  void registerUser({
    required String userId,
    required String name,
    required String email,
  });

  void linkPatientAndCaregiver({
    required String patientUserId,
    required String patientName,
    required String patientEmail,
    required String caregiverName,
    required String caregiverEmail,
  });

  List<LinkedUserProfile> linkedCaregiversForPatient(String patientUserId);
  List<LinkedUserProfile> linkedPatientsForCaregiver(String caregiverUserId);

  List<MedicationRecord> medicationsForPatient(String patientUserId);

  void addMedication({
    required String patientUserId,
    required String medicationName,
    required String schedule,
  });

  // Syncs a new medication to the server after local store update
  Future<void> addMedicationToServer({
    required String patientUserId,
    required String medicationName,
    required String schedule,
  });

  void setMedicationTaken({
    required String patientUserId,
    required String medicationName,
    required String schedule,
    required bool taken,
  });

  List<String> notificationsForUser(String userId);
  List<String> missedDosesForUser(String userId);

  // Fetches a linked patient's medications from the server for the caregiver
  Future<Map<String, dynamic>> getCaregiverPatientMeds({
    required String caregiverUserId,
    required String patientUserId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class InMemoryGuardianCareRepository implements GuardianCareRepository {
  InMemoryGuardianCareRepository._();
  static final InMemoryGuardianCareRepository instance =
      InMemoryGuardianCareRepository._();

  final GuardianCareStore _store = GuardianCareStore.instance;

  // ── shared HTTP helpers ───────────────────────────────────────

  Future<Map<String, dynamic>> _get(String action,
      [Map<String, String>? params]) async {
    final uri = Uri.parse(kApiBase).replace(
      queryParameters: {'action': action, ...?params},
    );
    final res = await http.get(uri,
        headers: {'Accept': 'application/json'});
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(
      String action, Map<String, dynamic> body) async {
    final uri =
        Uri.parse(kApiBase).replace(queryParameters: {'action': action});
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── GuardianCareRepository implementation ─────────────────────

  @override
  ValueListenable<int> get versionListenable => _store.version;

  @override
  String normalizeUserId(String value) => _store.normalizeUserId(value);

  @override
  void registerUser({
    required String userId,
    required String name,
    required String email,
  }) {
    _store.registerUser(userId: userId, name: name, email: email);

    // Fire-and-forget: sync the user profile to the server
    _post('register_user', {
      'user_id': userId,
      'name': name,
      'email': email,
      'role': userId.contains('@caregiver') ? 'caregiver' : 'patient',
    }).catchError((_) {return <String, dynamic>{};}); // never crash the UI if offline
  }

  @override
  void linkPatientAndCaregiver({
    required String patientUserId,
    required String patientName,
    required String patientEmail,
    required String caregiverName,
    required String caregiverEmail,
  }) {
    // Update local in-memory store first (instant UI response)
    _store.linkPatientAndCaregiver(
      patientUserId: patientUserId,
      patientName: patientName,
      patientEmail: patientEmail,
      caregiverName: caregiverName,
      caregiverEmail: caregiverEmail,
    );

    // Persist to server (fire-and-forget)
    _post('link', {
      'patient_user_id': patientEmail,
      'patient_name': patientName,
      'patient_email': patientEmail,
      'caregiver_name': caregiverName,
      'caregiver_email': caregiverEmail,
    }).catchError((_) {return <String, dynamic>{};});
  }

  @override
  List<LinkedUserProfile> linkedCaregiversForPatient(String patientUserId) =>
      _store.linkedCaregiversForPatient(patientUserId);

  @override
  List<LinkedUserProfile> linkedPatientsForCaregiver(String caregiverUserId) =>
      _store.linkedPatientsForCaregiver(caregiverUserId);

  @override
  List<MedicationRecord> medicationsForPatient(String patientUserId) =>
      _store.medicationsForPatient(patientUserId);

  @override
  void addMedication({
    required String patientUserId,
    required String medicationName,
    required String schedule,
  }) {
    // Update local store immediately so the UI reacts
    _store.addMedication(
      patientUserId: patientUserId,
      medicationName: medicationName,
      schedule: schedule,
    );
  }

  @override
  Future<void> addMedicationToServer({
    required String patientUserId,
    required String medicationName,
    required String schedule,
  }) async {
    // Called by PatientHome after addMedication() to persist + notify caregivers
    await _post('add_medication', {
      'patient_user_id': patientUserId,
      'medication_name': medicationName,
      'schedule': schedule,
    });
  }

  @override
  void setMedicationTaken({
    required String patientUserId,
    required String medicationName,
    required String schedule,
    required bool taken,
  }) {
    _store.setMedicationTaken(
      patientUserId: patientUserId,
      medicationName: medicationName,
      schedule: schedule,
      taken: taken,
    );

    // Sync to server so caregivers see live taken/pending status
    _post('set_medication_taken', {
      'patient_user_id': patientUserId,
      'medication_name': medicationName,
      'schedule': schedule,
      'taken': taken,
    }).catchError((_) {return <String, dynamic>{};});
  }

  @override
  List<String> notificationsForUser(String userId) =>
      _store.notificationsForUser(userId);

  @override
  List<String> missedDosesForUser(String userId) =>
      _store.missedDosesForUser(userId);

  // ── NEW: fetch patient's medications from server for caregiver ─

  @override
  Future<Map<String, dynamic>> getCaregiverPatientMeds({
    required String caregiverUserId,
    required String patientUserId,
  }) async {
    return _get('caregiver_patient_meds', {
      'caregiver_user_id': caregiverUserId,
      'patient_user_id': patientUserId,
    });
  }
}

class GuardianCareRepositoryProvider {
  GuardianCareRepositoryProvider._();
  static GuardianCareRepository instance =
      InMemoryGuardianCareRepository.instance;
}