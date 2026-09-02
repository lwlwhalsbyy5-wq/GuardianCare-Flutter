import 'package:flutter/material.dart'; 
 
import 'role_selection.dart'; 
import '../shared/guardian_care_store.dart';
import '../shared/guardian_care_repository.dart';
 
class ProfilePage extends StatelessWidget { 
  static const String routeName = '/profile'; 
 
  const ProfilePage({super.key}); 
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar(title: const Text('Profile')), 
      body: Padding( 
        padding: const EdgeInsets.all(24.0), 
        child: Column( 
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [ 
            const Text( 
              'Profile', 
              style: TextStyle(fontSize: 28, fontWeight: 
FontWeight.bold), 
            ), 
            const SizedBox(height: 16), 
            const Text( 
              'Update your information and view your account settings.', 
              style: TextStyle(fontSize: 16, color: Colors.black54), 
            ), 
            const SizedBox(height: 24), 
            const ListTile( 
              leading: Icon(Icons.person_outline), 
              title: Text('Username'), 
              subtitle: Text('Patient User'), 
            ), 
            const ListTile( 
              leading: Icon(Icons.email_outlined), 
              title: Text('Email'), 
              subtitle: Text('patient@example.com'), 
            ), 
          ], 
        ), 
      ), 
    ); 
  } 
} 
 
class CaregiverManagementPage extends StatefulWidget { 
  static const String routeName = '/caregiverManagement'; 
 
  const CaregiverManagementPage({super.key}); 
 
  @override 
  State<CaregiverManagementPage> createState() => 
_CaregiverManagementPageState(); 
} 
 
class _CaregiverManagementPageState extends 
State<CaregiverManagementPage> { 
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); 
  final TextEditingController _nameController = 
TextEditingController(); 
  final TextEditingController _emailController = 
TextEditingController(); 
  final List<_Patient> _patients = []; 
  GuardianCareRepository get _store => GuardianCareRepositoryProvider.instance;

  ManagementPageArgs get _pageArgs {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ManagementPageArgs) {
      return args;
    }
    return ManagementPageArgs(
      context: const AppUserContext(
        userId: 'default-caregiver@caregiver.local',
        displayName: 'Caregiver',
        role: AppUserRole.caregiver,
      ),
      isPatientManagingCaregivers: false,
    );
  }
 
  @override 
  void dispose() { 
    _nameController.dispose(); 
    _emailController.dispose(); 
    super.dispose(); 
  } 
 
  bool get _isPatientManagingCaregivers => _pageArgs.isPatientManagingCaregivers;

  void _addPatient() { 
    if (_formKey.currentState?.validate() != true) { 
      return; 
    } 
 
    final enteredName = _nameController.text.trim();
    final enteredEmail = _emailController.text.trim();

    if (_isPatientManagingCaregivers) {
      _store.linkPatientAndCaregiver(
        patientUserId: _pageArgs.context.userId,
        patientName: _pageArgs.context.displayName,
        patientEmail: _pageArgs.context.userId,
        caregiverName: enteredName,
        caregiverEmail: enteredEmail,
      );
    } else {
      _store.linkPatientAndCaregiver(
        patientUserId: enteredEmail,
        patientName: enteredName,
        patientEmail: enteredEmail,
        caregiverName: _pageArgs.context.displayName,
        caregiverEmail: _pageArgs.context.userId,
      );
    }

    setState(() { 
      _patients.add( 
        _Patient( 
          name: enteredName, 
          email: enteredEmail, 
        ), 
      ); 
      _nameController.clear(); 
      _emailController.clear(); 
    }); 
 
    ScaffoldMessenger.of(context).showSnackBar( 
      SnackBar(
        content: Text(
          _isPatientManagingCaregivers
              ? 'Caregiver added successfully'
              : 'Patient added successfully',
        ),
      ), 
    ); 
  } 
 
  @override 
  Widget build(BuildContext context) { 
    final isPatientFlow = _isPatientManagingCaregivers;
    final title = isPatientFlow ? 'Caregiver Management' : 'Patient Management';
    final addTitle = isPatientFlow ? 'Add a Caregiver' : 'Add a Patient';
    final nameLabel = isPatientFlow ? 'Caregiver Name' : 'Patient Name';
    final emailLabel = isPatientFlow ? 'Caregiver Email' : 'Patient Email';
    final addButtonLabel = isPatientFlow ? '+ Add Caregiver' : '+ Add Patient';
    final listTitle = isPatientFlow ? 'Your Caregivers' : 'Your Patients';
    final emptyText = isPatientFlow ? 'No caregivers added yet' : 'No patients added yet';
    final listIcon = isPatientFlow ? Icons.group : Icons.favorite;
    final args = _pageArgs;
    final linkedUsers = isPatientFlow
        ? _store.linkedCaregiversForPatient(args.context.userId)
        : _store.linkedPatientsForCaregiver(args.context.userId);

    return Scaffold( 
      backgroundColor: const Color(0xFFF6F5F2), 
      appBar: AppBar( 
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton( 
          icon: const Icon(Icons.arrow_back, color: Colors.black87), 
          onPressed: () => Navigator.pop(context), 
        ), 
        title: Text( 
          title, 
          style: TextStyle(color: Colors.black87, fontFamily: 'Serif'), 
        ), 
        actions: [ 
          IconButton( 
            icon: const Icon(Icons.warning_amber_rounded, color: 
Colors.orange), 
            onPressed: () { 
              Navigator.pushNamed(
                context,
                '/missedDoses',
                arguments: args.context,
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
                arguments: args.context,
              ); 
            }, 
          ), 
        ], 
      ), 
      drawer: _buildDrawer(context, activePatientManagement: true), 
      body: SingleChildScrollView( 
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 
16.0), 
        child: Column( 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [ 
            Card( 
              shape: RoundedRectangleBorder( 
                borderRadius: BorderRadius.circular(18), 
                side: const BorderSide(color: Color(0xFF88AF81), width: 
1), 
              ), 
              elevation: 0, 
              child: Padding( 
                padding: const EdgeInsets.all(20.0), 
                child: Form( 
                  key: _formKey, 
                  child: Column( 
                    crossAxisAlignment: CrossAxisAlignment.stretch, 
                    children: [ 
                      Text( 
                        addTitle, 
                        style: TextStyle( 
                          fontSize: 22, 
                          fontWeight: FontWeight.bold, 
                          fontFamily: 'Serif', 
                        ), 
                      ), 
                      const SizedBox(height: 16), 
                      TextFormField( 
                        controller: _nameController, 
                        decoration: InputDecoration( 
                          labelText: nameLabel, 
                          hintText: isPatientFlow ? 'Caregiver name' : 'Patient name', 
                          border: OutlineInputBorder( 
                            borderRadius: BorderRadius.circular(16), 
                            borderSide: const BorderSide(color: 
Color(0xFF88AF81)), 
                          ), 
                          enabledBorder: OutlineInputBorder( 
                            borderRadius: BorderRadius.circular(16), 
                            borderSide: const BorderSide(color: 
Color(0xFF88AF81)), 
                          ), 
                        ), 
                        validator: (value) { 
                          if (value == null || value.trim().isEmpty) { 
                            return isPatientFlow
                                ? 'Please enter a caregiver name'
                                : 'Please enter a patient name'; 
                          } 
                          return null; 
                        }, 
                      ), 
                      const SizedBox(height: 16), 
                      TextFormField( 
                        controller: _emailController, 
                        keyboardType: TextInputType.emailAddress, 
                        decoration: InputDecoration( 
                          labelText: emailLabel, 
                          hintText: isPatientFlow
                              ? 'caregiver@example.com'
                              : 'patient@example.com', 
                          border: OutlineInputBorder( 
                            borderRadius: BorderRadius.circular(16), 
                            borderSide: const BorderSide(color: 
Color(0xFF88AF81)), 
                          ), 
                          enabledBorder: OutlineInputBorder( 
                            borderRadius: BorderRadius.circular(16), 
                            borderSide: const BorderSide(color: 
Color(0xFF88AF81)), 
                          ), 
                        ), 
                        validator: (value) { 
                          if (value == null || value.trim().isEmpty) { 
                            return 'Please enter an email'; 
                          } 
                          if 
(!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) { 
                            return 'Enter a valid email address'; 
                          } 
                          return null; 
                        }, 
                      ), 
                      const SizedBox(height: 20), 
                      ElevatedButton( 
                        style: ElevatedButton.styleFrom( 
                          backgroundColor: const Color(0xFF8E8D8A), 
                          shape: RoundedRectangleBorder( 
                            borderRadius: BorderRadius.circular(16), 
                          ), 
                          padding: const EdgeInsets.symmetric(vertical: 
16), 
                        ), 
                        onPressed: _addPatient, 
                        child: Text( 
                          addButtonLabel, 
                          style: const TextStyle(color: Colors.white, 
fontWeight: FontWeight.bold), 
                        ), 
                      ), 
                    ], 
                  ), 
                ), 
              ), 
            ), 
            const SizedBox(height: 28), 
            Text( 
              listTitle, 
              style: TextStyle( 
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                fontFamily: 'Serif', 
              ), 
            ), 
            const SizedBox(height: 16), 
            if (linkedUsers.isEmpty) 
              Row( 
                children: [ 
                  Icon(listIcon, color: const Color(0xFF88AF81), size: 20), 
                  const SizedBox(width: 12), 
                  Text( 
                    emptyText, 
                    style: const TextStyle(fontSize: 15, color: Colors.grey), 
                  ), 
                ], 
              ) 
            else 
              Column( 
                children: linkedUsers 
                    .map( 
                      (patient) => Container( 
                        width: double.infinity, 
                        margin: const EdgeInsets.only(bottom: 12), 
                        padding: const EdgeInsets.all(16), 
                        decoration: BoxDecoration( 
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(16), 
                          border: Border.all(color: const 
Color(0xFFE5E2D7)), 
                        ), 
                        child: Column( 
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [ 
                            Text( 
                              patient.name, 
                              style: const TextStyle( 
                                fontSize: 16, 
                                fontWeight: FontWeight.bold, 
                              ), 
                            ), 
                            const SizedBox(height: 6), 
                            Text( 
                              patient.email, 
                              style: const TextStyle(fontSize: 14, 
color: Colors.grey), 
                            ), 
                          ], 
                        ), 
                      ), 
                    ) 
                    .toList(), 
              ), 
            const SizedBox(height: 32), 
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
      ), 
    ); 
  } 
 
  Widget _buildDrawer(BuildContext context, {required bool 
activePatientManagement}) { 
    final isPatientFlow = _isPatientManagingCaregivers;
    return Drawer( 
      child: Column( 
        crossAxisAlignment: CrossAxisAlignment.stretch, 
        children: [ 
          Container( 
            color: const Color(0xFF88AF81), 
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24), 
            child: Column( 
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [ 
                const Text( 
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
                  isPatientFlow ? 'Patient Account' : 'Caregiver Account', 
                  style: const TextStyle(fontSize: 16, color: 
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
                  leading: Icon(isPatientFlow ? Icons.group : Icons.favorite_border), 
                  title: Text(isPatientFlow ? 'Caregiver Management' : 'Patient Management'), 
                  tileColor: activePatientManagement ? const 
Color(0xFFEEECE4) : null, 
                  onTap: () { 
                    Navigator.pop(context); 
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
} 
class _Patient { 
final String name; 
final String email; 
_Patient({required this.name, required this.email}); 
}