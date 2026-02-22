import 'package:flutter/material.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Blueprint: Supabase initialized ONCE, only in SupabaseService
  await SupabaseService.initialize();

  runApp(const AdminApp());
}
