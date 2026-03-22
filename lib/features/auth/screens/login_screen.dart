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
  bool _obscurePassword = true;

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
      body: Stack(
        children: [
          /// 🔹 BACKGROUND IMAGE
          SizedBox.expand(
            child: Image.asset("assets/images/login_bg.png", fit: BoxFit.cover),
          ),

          /// 🔹 DARK OVERLAY
          Container(color: Colors.black.withOpacity(0.6)),

          /// 🔹 CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  /// 🔹 TOP BAR (Yala 360 + Language)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "YALA 360",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),

                      DropdownButton<String>(
                        dropdownColor: Colors.black,
                        value: langProvider.lang,
                        style: const TextStyle(color: Colors.white),
                        underline: const SizedBox(),
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
                    ],
                  ),

                  const Spacer(),

                  /// 🔹 LOGIN TITLE
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "LOGIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 🔹 USERNAME
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      labelText: AppTranslations.t('username'),
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 🔹 PASSWORD
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      labelText: AppTranslations.t('password'),
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// 🔹 LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              AppTranslations.t('login'),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
