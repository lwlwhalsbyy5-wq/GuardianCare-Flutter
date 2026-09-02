// ignore_for_file: unused_element_parameter

import 'package:flutter/foundation.dart';

enum AppUserRole { patient, caregiver }

class AppUserContext {
  final String userId;
  final String displayName;
  final AppUserRole role;

  const AppUserContext({
    required this.userId,
    required this.displayName,
    required this.role,
  });
}

class ManagementPageArgs {
  final AppUserContext context;
  final bool isPatientManagingCaregivers;

  const ManagementPageArgs({
    required this.context,
    required this.isPatientManagingCaregivers,
  });
}

class MedicationRecord {
  final String name;
  final String schedule;
  bool taken;

  MedicationRecord({
    required this.name,
    required this.schedule,
    this.taken = false,
  });
}

class LinkedUserProfile {
  final String id;
  final String name;
  final String email;

  const LinkedUserProfile({
    required this.id,
    required this.name,
    required this.email,
  });
}

class _DoseReminder {
  final String medicationName;
  final String schedule;
  bool isResolved;

  _DoseReminder({
    required this.medicationName,
    required this.schedule,
    
    this.isResolved = false,
  });
}

class GuardianCareStore {
  GuardianCareStore._();
  static final GuardianCareStore instance = GuardianCareStore._();

  final ValueNotifier<int> version = ValueNotifier<int>(0);

  final Map<String, LinkedUserProfile> _profiles = {};
  final Map<String, Set<String>> _patientToCaregivers = {};
  final Map<String, Set<String>> _caregiverToPatients = {};
  final Map<String, List<MedicationRecord>> _medicationsByPatient = {};
  final Map<String, List<String>> _notificationsByUser = {};
  final Map<String, List<_DoseReminder>> _doseRemindersByUser = {};

  String normalizeUserId(String value) => value.trim().toLowerCase();

  void registerUser({
    required String userId,
    required String name,
    required String email,
  }) {
    final normalizedId = normalizeUserId(userId);
    final next = LinkedUserProfile(
      id: normalizedId,
      name: name.trim().isEmpty ? email.trim() : name.trim(),
      email: email.trim(),
    );
    final current = _profiles[normalizedId];
    if (current?.name == next.name && current?.email == next.email) {
      return;
    }
    _profiles[normalizedId] = next;
    _notify();
  }

  LinkedUserProfile _upsertByEmail({
    required String name,
    required String email,
  }) {
    final normalizedEmail = normalizeUserId(email);
    final next = LinkedUserProfile(
      id: normalizedEmail,
      name: name.trim().isEmpty ? email.trim() : name.trim(),
      email: email.trim(),
    );
    _profiles[normalizedEmail] = next;
    return next;
  }

  void linkPatientAndCaregiver({
    required String patientUserId,
    required String patientName,
    required String patientEmail,
    required String caregiverName,
    required String caregiverEmail,
  }) {
    final patient = _upsertByEmail(name: patientName, email: patientEmail);
    final caregiver = _upsertByEmail(name: caregiverName, email: caregiverEmail);
    _patientToCaregivers.putIfAbsent(patient.id, () => <String>{}).add(caregiver.id);
    _caregiverToPatients.putIfAbsent(caregiver.id, () => <String>{}).add(patient.id);
    _addNotification(patient.id, 'Caregiver ${caregiver.name} linked to your account.');
    _addNotification(caregiver.id, 'Patient ${patient.name} linked to your account.');
    _notify();
  }

  List<LinkedUserProfile> linkedCaregiversForPatient(String patientUserId) {
    final ids = _patientToCaregivers[normalizeUserId(patientUserId)] ?? <String>{};
    return ids.map((id) => _profiles[id]).whereType<LinkedUserProfile>().toList();
  }

  List<LinkedUserProfile> linkedPatientsForCaregiver(String caregiverUserId) {
    final ids = _caregiverToPatients[normalizeUserId(caregiverUserId)] ?? <String>{};
    return ids.map((id) => _profiles[id]).whereType<LinkedUserProfile>().toList();
  }

  List<MedicationRecord> medicationsForPatient(String patientUserId) {
    return List<MedicationRecord>.from(
      _medicationsByPatient[normalizeUserId(patientUserId)] ?? const <MedicationRecord>[],
    );
  }

  void addMedication({
    required String patientUserId,
    required String medicationName,
    required String schedule,
  }) {
    final patientId = normalizeUserId(patientUserId);
    _medicationsByPatient.putIfAbsent(patientId, () => <MedicationRecord>[]).add(
          MedicationRecord(name: medicationName, schedule: schedule, taken: false),
        );
    _addNotification(patientId, 'Medication "$medicationName" scheduled: $schedule.');
    _addDoseReminder(patientId, medicationName: medicationName, schedule: schedule);

    final caregivers = _patientToCaregivers[patientId] ?? <String>{};
    for (final caregiverId in caregivers) {
      _addNotification(caregiverId, 'Patient medication "$medicationName" scheduled: $schedule.');
      _addDoseReminder(caregiverId, medicationName: medicationName, schedule: schedule);
    }
    _notify();
  }

  void setMedicationTaken({
    required String patientUserId,
    required String medicationName,
    required String schedule,
    required bool taken,
  }) {
    final patientId = normalizeUserId(patientUserId);
    final meds = _medicationsByPatient[patientId];
    if (meds != null) {
      for (final med in meds) {
        if (med.name == medicationName && med.schedule == schedule) {
          med.taken = taken;
        }
      }
    }

    final recipients = <String>{patientId, ...?_patientToCaregivers[patientId]};
    for (final userId in recipients) {
      final reminders = _doseRemindersByUser[userId];
      if (reminders == null) {
        continue;
      }
      for (final reminder in reminders) {
        if (reminder.medicationName == medicationName &&
            reminder.schedule == schedule) {
          reminder.isResolved = taken;
        }
      }
      if (taken) {
        _addNotification(userId, 'Dose marked as taken: $medicationName ($schedule).');
      }
    }
    _notify();
  }

  List<String> notificationsForUser(String userId) {
    return List<String>.from(
      _notificationsByUser[normalizeUserId(userId)] ?? const <String>[],
    );
  }

  List<String> missedDosesForUser(String userId) {
    final reminders = _doseRemindersByUser[normalizeUserId(userId)] ?? const <_DoseReminder>[];
    return reminders
        .where((r) => !r.isResolved)
        .map((r) => '${r.medicationName} (${r.schedule})')
        .toList();
  }

  void _addNotification(String userId, String message) {
    _notificationsByUser.putIfAbsent(userId, () => <String>[]).insert(0, message);
  }

  void _addDoseReminder(
    String userId, {
    required String medicationName,
    required String schedule,
  }) {
    _doseRemindersByUser.putIfAbsent(userId, () => <_DoseReminder>[]).add(
          _DoseReminder(medicationName: medicationName, schedule: schedule),
        );
  }

  void _notify() {
    version.value = version.value + 1;
  }
}
