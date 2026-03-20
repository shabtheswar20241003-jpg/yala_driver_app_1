import 'package:flutter/material.dart';
import 'core/services/supabase_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/driver_dashboard_screen.dart';
import '../../../features/incidents/screens/incident_report_screen.dart';
import 'core/constants/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/translations/language_provider.dart';
// DO NOT import map here unless you plan to use it in routes

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SupabaseConfig.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const DriverApp(),
    ),
  );
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yala Safari Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (c) => const LoginScreen(),
        // keep this for quick testing — ideally Login pushes dashboard with real driverId
        '/dashboard': (c) =>
            const DriverDashboardScreen(driverId: "driver_001"),
        '/incident': (c) => const IncidentReportScreen(),
        // removed '/map' route because MapScreen needs a runtime driverId
      },
    );
  }
}
