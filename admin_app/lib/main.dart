import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/admin_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AdminConfig.supabaseUrl,
    anonKey: AdminConfig.supabaseAnonKey,
  );

  runApp(const AdminApp());
}
