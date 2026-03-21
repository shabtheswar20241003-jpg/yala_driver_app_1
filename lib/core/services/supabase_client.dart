import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = "https://entzwknecnwcbspqcbuk.supabase.co/";
  static const String supabaseAnonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVudHp3a25lY253Y2JzcHFjYnVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM1MTA5MDUsImV4cCI6MjA4OTA4NjkwNX0.96EH2JKnFsT5XfxNFMX-RfbJByOKSy-yT0sCEZsBP6g";

  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
