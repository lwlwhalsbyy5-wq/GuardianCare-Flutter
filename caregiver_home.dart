// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart'; 
 
import 'profile_page.dart'; 
import 'role_selection.dart'; 
import '../shared/guardian_care_store.dart';
import '../shared/guardian_care_repository.dart';
 
class CaregiverHome extends StatelessWidget { 
  static const String routeName = '/caregiverHome'; 
 
  const CaregiverHome({super.key}); 
 
  @override 
  Widget build(BuildContext context) { 
    final username = ModalRoute.of(context)?.settings.arguments as 
String?; 
    final displayName = username?.isNotEmpty == true ? username! : 
'Caregiver'; 
    final store = GuardianCareRepositoryProvider.instance;
    final caregiverId = store.normalizeUserId('$displayName@caregiver.local');
    final userContext = AppUserContext(
      userId: caregiverId,
      displayName: displayName,
      role: AppUserRole.caregiver,
    );

    store.registerUser(
      userId: caregiverId,
      name: displayName,
      email: '$displayName@caregiver.local',
    );
 
    return Scaffold( 
      backgroundColor: const Color(0xFFF6F5F2), 
      appBar: AppBar( 
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        title: const Text(''), 
        actions: [ 
          IconButton( 
            icon: const Icon(Icons.warning_amber_rounded, color: 
Colors.orange), 
            onPressed: () { 
              Navigator.pushNamed(
                context,
                '/missedDoses',
                arguments: userContext,
              ); 
            }, 
          ), 
          IconButton( 
            icon: const Icon(Icons.notifications_none, color: 
Colors.black87), 
            onPressed: () { 
              Navigator.pushNamed(
                context,
                '/notifications',
                arguments: userContext,
              ); 
            }, 
          ), 
        ], 
      ), 
      drawer: _buildDrawer(
        context,
        activePatientManagement: false,
        userContext: userContext,
      ), 
      body: Padding( 
        padding: const EdgeInsets.symmetric(horizontal: 24.0), 
        child: Column( 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [ 
            const SizedBox(height: 8), 
            Text( 
              'Hello, $displayName', 
              style: const TextStyle( 
                fontSize: 36, 
                fontWeight: FontWeight.w900, 
                color: Colors.black87, 
                fontFamily: 'Serif', 
              ), 
            ), 
            const SizedBox(height: 8), 
            Expanded( 
              child: ValueListenableBuilder<int>(
                valueListenable: store.versionListenable,
                builder: (context, _, __) {
                  final linkedPatients = store.linkedPatientsForCaregiver(caregiverId);
                  return Center( 
                    child: Column( 
                      mainAxisSize: MainAxisSize.min, 
                      children: [ 
                    Container( 
                      height: 96, 
                      width: 96, 
                      decoration: const BoxDecoration( 
                        color: Color(0xFFD4E9D0), 
                        shape: BoxShape.circle, 
                      ), 
                      child: const Center( 
                        child: Icon( 
                          Icons.group_outlined, 
                          size: 40, 
                          color: Color(0xFF3E7A3A), 
                        ), 
                      ), 
                    ), 
                    const SizedBox(height: 24), 

                    // استبدلي السطر الذي يعرض الأسماء بهذا الكود التفاعلي:
linkedPatients.isEmpty 
    ? const Text('Add patients from the Patient Management menu to start monitoring', textAlign: TextAlign.center)
    : Column(
        children: linkedPatients.map((patient) {
          return ListTile(
            title: Text(patient.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Tap to view adherence status', textAlign: TextAlign.center),
           onTap: () async {
  // Show loading indicator while fetching
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: Color(0xFF5A8F52)),
    ),
  );

  try {
    final result = await store.getCaregiverPatientMeds(
      caregiverUserId: caregiverId,
      patientUserId: patient.id,
    );
    if (!context.mounted) return;
    Navigator.pop(context); // dismiss loader

    final meds = result['medications'] as List<dynamic>? ?? [];
    final summary = result['summary'] as Map<String, dynamic>? ?? {};

    // Show bottom sheet — same app style, no architecture change
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF6F5F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // Patient name header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      color: Color(0xFF3E7A3A)),
                  const SizedBox(width: 8),
                  Text(
                    patient.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Adherence summary row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _SummaryChip(
                    label: 'Total',
                    value: '${summary['total'] ?? 0}',
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Taken',
                    value: '${summary['taken'] ?? 0}',
                    color: const Color(0xFF5A8F52),
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Missed',
                    value: '${summary['missed'] ?? 0}',
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Adherence',
                    value: '${summary['adherence_pct'] ?? 0}%',
                    color: const Color(0xFF3E7A3A),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // Medications list
            Expanded(
              child: meds.isEmpty
                  ? const Center(
                      child: Text(
                        'No medications added yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: meds.length,
                      itemBuilder: (_, i) {
                        final med = meds[i] as Map<String, dynamic>;
                        final isTaken = med['taken'] == true;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                // Medication icon
                                Container(
                                  height: 44, width: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.medication,
                                      color: Colors.grey, size: 24),
                                ),
                                const SizedBox(width: 14),

                                // Name + schedule
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med['name'] as String? ?? '',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          decoration: isTaken
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFE5D0),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              med['schedule'] as String? ?? '',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFFBF6020)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Taken / Pending badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isTaken
                                        ? const Color(0xFFD4E9D0)
                                        : const Color(0xFFFFE5D0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isTaken ? 'Taken' : 'Pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isTaken
                                          ? const Color(0xFF305C2F)
                                          : const Color(0xFFBF6020),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  } catch (_) {
    if (context.mounted) {
      Navigator.pop(context); // dismiss loader
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load patient data. Check your connection.'),
        ),
      );
    }
  }
},
          );
        }).toList(),
      ),
                    const SizedBox(height: 12), 
                    Text( 
                      linkedPatients.isEmpty 
                          ? 'Add patients from the Patient Management menu to start monitoring' 
                          : linkedPatients.map((e) => e.name).join(', '), 
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
              );
                },
              ), 
            ), 
          ], 
        ), 
      ), 
    ); 
  } 
 
  Widget _buildDrawer(
    BuildContext context, {
    required bool activePatientManagement,
    required AppUserContext userContext,
  }) { 
    return Drawer( 
      child: Column( 
        crossAxisAlignment: CrossAxisAlignment.stretch, 
        children: [ 
          Container( 
            color: const Color(0xFF88AF81), 
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24), 
            child: Column( 
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: const [ 
                Text( 
                  'Guardiancare', 
                  style: TextStyle( 
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white, 
                    fontFamily: 'Serif', 
                  ), 
                ), 
                SizedBox(height: 8), 
                Text( 
                  'Caregiver Account', 
                  style: TextStyle(fontSize: 16, color: 
Colors.white70), 
                ), 
              ], 
            ), 
          ), 
          Expanded( 
            child: ListView( 
              padding: EdgeInsets.zero, 
              children: [ 
                ListTile( 
                  leading: const Icon(Icons.person_outline), 
                  title: const Text('Profile'), 
                  onTap: () { 
                    Navigator.pop(context); 
                    Navigator.pushNamed(context, 
ProfilePage.routeName); 
                  }, 
                ), 
                ListTile( 
                  leading: const Icon(Icons.favorite_border), 
                  title: const Text('Patient Management'), 
                  tileColor: activePatientManagement ? const 
Color(0xFFEEECE4) : null, 
                  onTap: () { 
                    Navigator.pop(context); 
                    Navigator.pushNamed(
                      context,
                      CaregiverManagementPage.routeName,
                      arguments: ManagementPageArgs(
                        context: userContext,
                        isPatientManagingCaregivers: false,
                      ),
                    ); 
                  }, 
                ), 
                ListTile( 
                  leading: const Icon(Icons.language), 
                  title: const Text('Language'), 
                  onTap: () { 
                    Navigator.pop(context); 
                    Navigator.pushNamed(context, '/languageSelection'); 
                  }, 
                ), 
              ], 
            ), 
          ), 
          const Divider(height: 1), 
          ListTile( 
            leading: const Icon(Icons.exit_to_app, color: Colors.red), 
            title: const Text('Log Out', style: TextStyle(color: 
Colors.red)), 
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
    ); 
  } 
} // Helper widget for the adherence summary chips — keeps caregiver_home self-contained
class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

 
