import 'package:flutter/material.dart'; 
 
import 'screens/auth_pages.dart'; 
import 'screens/caregiver_home.dart'; 
import 'screens/medication_pages.dart'; 
import 'screens/patient_home.dart'; 
import 'screens/profile_page.dart'; 
import 'screens/role_selection.dart'; 
import 'screens/splash_screen.dart'; 
 
void main() { 
  runApp(const MyApp()); 
} 
 
class MyApp extends StatelessWidget { 
  const MyApp({super.key}); 
 
  static const String splashRoute = SplashScreen.routeName; 
  static const String roleSelectionRoute = RoleSelectionPage.routeName; 
  static const String loginRoute = LoginPage.routeName; 
  static const String signupRoute = SignupPage.routeName; 
  static const String patientHomeRoute = PatientHome.routeName; 
  static const String caregiverHomeRoute = CaregiverHome.routeName; 
  static const String medicationEntryRoute = 
MedicationEntryPage.routeName; 
  static const String profileRoute = ProfilePage.routeName; 
  static const String caregiverManagementRoute = 
      CaregiverManagementPage.routeName; 
  static const String missedDosesRoute = MissedDosesPage.routeName; 
  static const String notificationsRoute = NotificationsPage.routeName; 
  static const String languageSelectionRoute = 
LanguageSelectionPage.routeName; 
 
  @override 
  Widget build(BuildContext context) { 
    final theme = ThemeData( 
      primaryColor: const Color(0xFFC8E6C9), 
      colorScheme: ColorScheme.fromSeed( 
        seedColor: const Color(0xFFC8E6C9), 
        primary: const Color(0xFFC8E6C9), 
      ), 
      fontFamily: 'Serif', 
      appBarTheme: const AppBarTheme( 
        backgroundColor: Color(0xFFC8E6C9), 
        foregroundColor: Colors.black, 
      ), 
      scaffoldBackgroundColor: Colors.white, 
      useMaterial3: true, 
    ); 
 
    return MaterialApp( 
      title: 'HCI App', 
      debugShowCheckedModeBanner: false, 
      theme: theme, 
      initialRoute: splashRoute, 
      routes: { 
        splashRoute: (context) => const SplashScreen(), 
        loginRoute: (context) => const LoginPage(), 
        signupRoute: (context) => const SignupPage(), 
        roleSelectionRoute: (context) => const RoleSelectionPage(), 
        patientHomeRoute: (context) { 
          final username = 
              ModalRoute.of(context)?.settings.arguments as String?; 
          return PatientHome(username: username ?? 'Patient'); 
        }, 
        caregiverHomeRoute: (context) => const CaregiverHome(), 
        medicationEntryRoute: (context) => const MedicationEntryPage(), 
        profileRoute: (context) => const ProfilePage(), 
        caregiverManagementRoute: (context) => const 
CaregiverManagementPage(), 
        missedDosesRoute: (context) => const MissedDosesPage(), 
        notificationsRoute: (context) => const NotificationsPage(), 
        languageSelectionRoute: (context) => const 
LanguageSelectionPage(), 
      }, 
    ); 
  } 
} 
