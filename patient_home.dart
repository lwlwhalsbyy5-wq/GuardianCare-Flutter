// ignore_for_file: deprecated_member_use 
 
import 'package:flutter/material.dart'; 
 
import 'medication_pages.dart'; 
import 'profile_page.dart'; 
import 'role_selection.dart'; 
import '../shared/guardian_care_store.dart'; 
import '../shared/guardian_care_repository.dart'; 
 
class PatientHome extends StatefulWidget { 
  static const String routeName = '/patientHome'; 
 
  final String username; 
  const PatientHome({super.key, this.username = 'User'}); 
 
  @override 
  State<PatientHome> createState() => _PatientHomeState(); 
} 
 
class _PatientHomeState extends State<PatientHome> { 
  final List<_MedicationItem> _medications = []; 
  GuardianCareRepository get _store => GuardianCareRepositoryProvider.instance; 

  String get _patientId => _store.normalizeUserId('${widget.username}@patient.local'); 

  AppUserContext get _userContext => AppUserContext( 
    userId: _patientId, 
    displayName: widget.username, 
    role: AppUserRole.patient, 
  ); 

 @override
void initState() {
  super.initState();

  // Register user in local store AND server
  _store.registerUser(
    userId: _patientId,
    name: widget.username,
    email: '${widget.username}@patient.local',
  );

  // Load from local in-memory store first (instant)
  final existing = _store.medicationsForPatient(_patientId);
  _medications.addAll(
    existing
        .map((med) => _MedicationItem(
              name: med.name,
              schedule: med.schedule,
              taken: med.taken,
            ))
        .toList(),
  );
}
 
 void _toggleMedicationTaken(int index, bool value) {
  final item = _medications[index];
  setState(() {
    item.taken = value;
  });
  // Updates local store + syncs taken/pending status to server
  // so the caregiver dashboard reflects the change immediately
  _store.setMedicationTaken(
    patientUserId: _patientId,
    medicationName: item.name,
    schedule: item.schedule,
    taken: value,
  );
}
 
  void _deleteMedication(int index) { 
    setState(() { 
      _medications.removeAt(index); 
    }); 
  } 
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      backgroundColor: const Color(0xFFF6F5F2), 
      appBar: AppBar( 
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        actions: [ 
          IconButton( 
            icon: const Icon(Icons.warning_amber_rounded, color: 
Colors.orange), 
            onPressed: () { 
              Navigator.pushNamed( 
                context, 
                MissedDosesPage.routeName, 
                arguments: _userContext, 
              ); 
            }, 
          ), 
          IconButton( 
            icon: const Icon(Icons.notifications_none, color: 
Colors.black87), 
            onPressed: () { 
              Navigator.pushNamed( 
                context, 
                NotificationsPage.routeName, 
                arguments: _userContext, 
              ); 
            }, 
          ), 
        ], 
      ), 
      drawer: Drawer( 
        child: ListView( 
          padding: EdgeInsets.zero, 
          children: [ 
            UserAccountsDrawerHeader( 
              accountName: Text(widget.username), 
              accountEmail: const Text('Patient Account'), 
              currentAccountPicture: CircleAvatar( 
                backgroundColor: 
Theme.of(context).colorScheme.onPrimary, 
                child: Text( 
                  widget.username.isNotEmpty 
                      ? widget.username[0].toUpperCase() 
                      : 'U', 
                  style: const TextStyle(fontSize: 28, color: 
Colors.white), 
                ), 
              ), 
              decoration: BoxDecoration( 
                color: Theme.of(context).colorScheme.primary, 
              ), 
            ), 
            ListTile( 
              leading: const Icon(Icons.person), 
              title: const Text('Profile'), 
              onTap: () { 
                Navigator.pop(context); 
                Navigator.pushNamed(context, ProfilePage.routeName); 
              }, 
            ), 
            ListTile( 
              leading: const Icon(Icons.group), 
              title: const Text('Caregiver Management'), 
              onTap: () { 
                Navigator.pop(context); 
                Navigator.pushNamed( 
                  context, 
                  CaregiverManagementPage.routeName, 
                  arguments: ManagementPageArgs( 
                    context: _userContext, 
                    isPatientManagingCaregivers: true, 
                  ), 
                ); 
              }, 
            ), 
            ListTile( 
              leading: const Icon(Icons.language), 
              title: const Text('Language'), 
              onTap: () { 
                Navigator.pop(context); 
                Navigator.pushNamed(context, 
LanguageSelectionPage.routeName); 
              }, 
            ), 
            ListTile( 
              leading: const Icon(Icons.logout), 
              title: const Text('Logout'), 
              onTap: () { 
                Navigator.pop(context); 
                Navigator.pushNamedAndRemoveUntil( 
                  context, 
                  RoleSelectionPage.routeName, 
                  (route) => false, 
                ); 
              }, 
            ), 
          ], 
        ), 
      ), 
      body: Padding( 
        padding: const EdgeInsets.symmetric(horizontal: 24.0), 
        child: Column( 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [ 
            const SizedBox(height: 8), 
            const Text( 
              'Guardiancare', 
              style: TextStyle( 
                fontSize: 36, 
                fontWeight: FontWeight.w900, 
                color: Colors.black87, 
                fontFamily: 'Serif', 
              ), 
            ), 
            const SizedBox(height: 8), 
            Text( 
              'Hello, ${widget.username.isNotEmpty ? widget.username : 
'User'}', 
              style: TextStyle(fontSize: 16, color: Colors.grey[600]), 
            ), 
            const SizedBox(height: 24), 
            Expanded( 
              child: _medications.isEmpty 
                  ? Center( 
                      child: Column( 
                        mainAxisSize: MainAxisSize.min, 
                        children: [ 
                          Container( 
                            height: 96, 
                            width: 96, 
                            decoration: BoxDecoration( 
                              color: const Color(0xFFD9F1E0), 
                              shape: BoxShape.circle, 
                            ), 
                            child: const Center( 
                              child: Icon( 
                                Icons.medication, 
                                size: 40, 
                                color: Color(0xFF2E7D32), 
                              ), 
                            ), 
                          ), 
                          const SizedBox(height: 24), 
                          const Text( 
                            'No medications yet', 
                            style: TextStyle( 
                              fontSize: 22, 
                              fontWeight: FontWeight.bold, 
                            ), 
                          ), 
                          const SizedBox(height: 12), 
                          const Text( 
                            'Add your first medication to start tracking doses', 
                            textAlign: TextAlign.center, 
                            style: TextStyle(fontSize: 15, color: 
Colors.grey), 
                          ), 
                          const SizedBox(height: 24), 
                          const Text( 
                            '"Never miss a dose or follow-up — Guardiancare App keeps you on track."', 
                            textAlign: TextAlign.center, 
                            style: TextStyle( 
                              fontSize: 14, 
                              color: Colors.black54, 
                              fontStyle: FontStyle.italic, 
                              fontFamily: 'Serif', 
                            ), 
                          ), 
                        ], 
                      ), 
                    ) 
                  : ListView.builder( 
                      padding: const EdgeInsets.only(bottom: 24), 
                      itemCount: _medications.length, 
                      itemBuilder: (context, index) { 
                        final medicine = _medications[index]; 
                        return Padding( 
                          padding: const EdgeInsets.symmetric(vertical: 
10), 
                          child: Card( 
                            shape: RoundedRectangleBorder( 
                              borderRadius: BorderRadius.circular(18), 
                            ), 
                            elevation: 2, 
                            child: Stack( 
                              children: [ 
                                Padding( 
                                  padding: const EdgeInsets.symmetric( 
                                    horizontal: 16, 
                                    vertical: 14, 
                                  ), 
                                  child: Row( 
                                    children: [ 
                                      Container( 
                                        height: 44, 
                                        width: 44, 
                                        decoration: BoxDecoration( 
                                          color: Colors.grey.shade200, 
                                          shape: BoxShape.circle, 
                                        ), 
                                        child: const Center( 
                                          child: Icon( 
                                            Icons.medication, 
                                            color: Colors.grey, 
                                            size: 24, 
                                          ), 
                                        ), 
                                      ), 
                                      const SizedBox(width: 14), 
                                      Expanded( 
                                        child: Column( 
                                          crossAxisAlignment: 
                                              CrossAxisAlignment.start, 
                                          children: [ 
                                            Text( 
                                              medicine.name, 
                                              style: TextStyle( 
                                                fontSize: 16, 
                                                fontWeight: 
FontWeight.w700, 
                                                decoration: 
medicine.taken 
                                                    ? 
TextDecoration.lineThrough 
                                                    : 
TextDecoration.none, 
                                              ), 
                                            ), 
                                            const SizedBox(height: 8), 
                                            Row( 
                                              children: [ 
                                                const Icon( 
                                                  Icons.access_time, 
                                                  size: 16, 
                                                  color: Colors.grey, 
                                                ), 
                                                const SizedBox(width: 
6), 
                                                Container( 
                                                  padding: 
                                                      const 
EdgeInsets.symmetric( 
                                                    horizontal: 10, 
                                                    vertical: 6, 
                                                  ), 
                                                  decoration: 
BoxDecoration( 
                                                    color: const 
Color(0xFFFFE5D0), 
                                                    borderRadius: 
                                                        
BorderRadius.circular(12), 
                                                  ), 
                                                  child: Text( 
                                                    medicine.schedule, 
                                                    style: const 
TextStyle( 
                                                      fontSize: 13, 
                                                      color: 
Colors.black87, 
                                                    ), 
                                                  ), 
                                                ), 
                                              ], 
                                            ), 
                                          ], 
                                        ), 
                                      ), 
                                      Column( 
                                        crossAxisAlignment: 
                                            CrossAxisAlignment.end, 
                                        children: [ 
                                          Text( 
                                            medicine.taken ? 'Taken' : 
'Pending', 
                                            style: TextStyle( 
                                              fontSize: 14, 
                                              fontWeight: 
FontWeight.w700, 
                                              color: medicine.taken 
                                                  ? Colors.green 
                                                  : Colors.orange, 
                                            ), 
                                          ), 
                                          Switch( 
                                            value: medicine.taken, 
                                            onChanged: (value) { 
                                              
_toggleMedicationTaken(index, value); 
                                            }, 
                                          ), 
                                        ], 
                                      ), 
                                    ], 
                                  ), 
                                ), 
                                Positioned( 
                                  top: 4, 
                                  right: 4, 
                                  child: IconButton( 
                                    icon: const Icon( 
                                      Icons.close, 
                                      size: 20, 
                                      color: Colors.grey, 
                                    ), 
                                    onPressed: () { 
                                      _deleteMedication(index); 
                                    }, 
                                  ), 
                                ), 
                              ], 
                            ), 
                          ), 
                        ); 
                      }, 
                    ), 
            ), 
            const SizedBox(height: 16), 
          ], 
        ), 
      ), 
      bottomNavigationBar: Padding( 
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), 
        child: ElevatedButton( 
         // Wherever you push MedicationEntryPage and handle the result:
onPressed: () async {
  final submission = await Navigator.pushNamed(
    context,
    MedicationEntryPage.routeName,
  ) as MedicationSubmission?;

  if (submission == null) return;

  // 1. Update local store (instant UI update)
  _store.addMedication(
    patientUserId: _patientId,
    medicationName: submission.name,
    schedule: submission.schedule,
  );

  setState(() {
    _medications.add(_MedicationItem(
      name: submission.name,
      schedule: submission.schedule,
      taken: false,
    ));
  });

  // 2. Sync to server in background so linked caregivers see it immediately
  _store.addMedicationToServer(
    patientUserId: _patientId,
    medicationName: submission.name,
    schedule: submission.schedule,
  ).catchError((_) {
    // Silent fail — local UI already updated
  });
},
          style: ElevatedButton.styleFrom( 
            backgroundColor: Colors.black, 
            foregroundColor: Colors.white, 
            padding: const EdgeInsets.symmetric(vertical: 18), 
            shape: RoundedRectangleBorder( 
              borderRadius: BorderRadius.circular(20), 
            ), 
          ), 
          child: const Text( 
            '+ New Medication?', 
            style: TextStyle(fontSize: 16, fontWeight: 
FontWeight.bold), 
          ), 
        ), 
      ), 
    ); 
  } 
} 
 
class _MedicationItem { 
  final String name; 
  final String schedule; 
  bool taken; 
 
  _MedicationItem({ 
    required this.name, 
    required this.schedule, 
    required this.taken, 
  }); 
} 
 
class MissedDosesPage extends StatelessWidget { 
  static const String routeName = '/missedDoses'; 
 
  const MissedDosesPage({super.key}); 
 
  @override 
  Widget build(BuildContext context) { 
    final args = ModalRoute.of(context)?.settings.arguments;
    final userContext = args is AppUserContext
        ? args
        : const AppUserContext(
            userId: 'default-patient@patient.local',
            displayName: 'Patient',
            role: AppUserRole.patient,
          );
    final missed = GuardianCareRepositoryProvider.instance.missedDosesForUser(
      userContext.userId,
    );
    return Scaffold( 
      appBar: AppBar(title: const Text('Missed Doses')), 
      body: missed.isEmpty
          ? Center( 
        child: Padding( 
          padding: const EdgeInsets.symmetric(horizontal: 24.0), 
          child: Column( 
            mainAxisSize: MainAxisSize.min, 
            children: [ 
              Container( 
                height: 120, 
                width: 120, 
                decoration: BoxDecoration( 
                  color: const Color(0xFFDFF7E8), 
                  shape: BoxShape.circle, 
                ), 
                child: const Center( 
                  child: Icon( 
                    Icons.warning_amber_rounded, 
                    size: 50, 
                    color: Colors.orange, 
                  ), 
                ), 
              ), 
              const SizedBox(height: 24), 
              const Text( 
                'No missed doses yet', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 24, fontWeight: 
FontWeight.bold), 
              ), 
              const SizedBox(height: 12), 
              const Text( 
                'You are all caught up. When a dose is missed, it will appear here.', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 16, color: Colors.grey), 
              ), 
            ], 
          ), 
        ), 
      )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: missed.length,
              itemBuilder: (context, index) {
                final item = missed[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    title: Text(item),
                    subtitle: Text(userContext.role == AppUserRole.patient
                        ? 'Missed by you'
                        : 'Missed by linked patient'),
                  ),
                );
              },
            ), 
    ); 
  } 
} 
 
class NotificationsPage extends StatelessWidget { 
  static const String routeName = '/notifications'; 
 
  const NotificationsPage({super.key}); 
 
  @override 
  Widget build(BuildContext context) { 
    final args = ModalRoute.of(context)?.settings.arguments;
    final userContext = args is AppUserContext
        ? args
        : const AppUserContext(
            userId: 'default-patient@patient.local',
            displayName: 'Patient',
            role: AppUserRole.patient,
          );
    final notifications = GuardianCareRepositoryProvider.instance.notificationsForUser(
      userContext.userId,
    );
    return Scaffold( 
      appBar: AppBar(title: const Text('Notifications')), 
      body: notifications.isEmpty
          ? Center( 
        child: Padding( 
          padding: const EdgeInsets.symmetric(horizontal: 24.0), 
          child: Column( 
            mainAxisSize: MainAxisSize.min, 
            children: [ 
              const Icon( 
                Icons.notifications_none, 
                size: 64, 
                color: Colors.black54, 
              ), 
              const SizedBox(height: 24), 
              const Text( 
                'No notifications yet', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 24, fontWeight: 
FontWeight.bold), 
              ), 
              const SizedBox(height: 12), 
              const Text( 
                'Future and current reminders will appear here when they are scheduled.', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 16, color: Colors.grey), 
              ), 
            ], 
          ), 
        ), 
      )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_none),
                    title: Text(notifications[index]),
                  ),
                );
              },
            ), 
    ); 
  } 
} 
 
class LanguageSelectionPage extends StatelessWidget { 
  static const String routeName = '/languageSelection'; 
 
  const LanguageSelectionPage({super.key}); 
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar(title: const Text('Language')), 
      body: Padding( 
        padding: const EdgeInsets.all(24.0), 
        child: Column( 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [ 
            const Text( 
              'Choose your language', 
              style: TextStyle(fontSize: 28, fontWeight: 
FontWeight.bold), 
            ), 
            const SizedBox(height: 16), 
            const ListTile( 
              leading: Icon(Icons.language), 
              title: Text('English'), 
            ), 
const ListTile( 
leading: Icon(Icons.language), 
title: Text('Español'), 
), 
const ListTile( 
leading: Icon(Icons.language), 
title: Text('اﻟﻌﺮﺑﻴﺔ'), 
), 
], 
), 
), 
); 
} 
}