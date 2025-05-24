import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String SUPABASE_URL = 'https://kxvjynsfxshwdkilglas.supabase.co';
  static const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4dmp5bnNmeHNod2RraWxnbGFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0ODg3NjQsImV4cCI6MjA2MzA2NDc2NH0.r-jiO70mw-SWC3NRjQU1IwtTE35vKFT25mvpY3lbdqM';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SUPABASE_URL,
      anonKey: SUPABASE_ANON_KEY,
    );
  }
} 