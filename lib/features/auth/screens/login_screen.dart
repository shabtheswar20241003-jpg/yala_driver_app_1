import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dashboard/driver_dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/translations/language_provider.dart';
import '../../../core/translations/app_translations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage("Enter username and password");
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('drivers')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response == null) {
        _showMessage("Invalid login credentials");
        setState(() => _loading = false);
        return;
      }

      final driverId = response['id'].toString();
      final jeepId = response['jeep_id'] ?? "Unknown";
      final block = response['block'] ?? "Unknown";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverDashboardScreen(
            driverId: driverId,
            jeepId: jeepId,
            block: block,
          ),
        ),
      );
    } catch (e) {
      _showMessage("Login failed");
    }

    setState(() {
      _loading = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Driver Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: DropdownButton<String>(
                value: langProvider.lang,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text("English")),
                  DropdownMenuItem(value: 'si', child: Text("සිංහල")),
                  DropdownMenuItem(value: 'ta', child: Text("தமிழ்")),
                ],
                onChanged: (value) {
                  if (value != null) {
                    langProvider.changeLanguage(value);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: AppTranslations.t('username'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppTranslations.t('password'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
