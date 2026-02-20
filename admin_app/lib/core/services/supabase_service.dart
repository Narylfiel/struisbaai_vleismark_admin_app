import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/admin_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AdminConfig.supabaseUrl,
      anonKey: AdminConfig.supabaseAnonKey,
    );
  }

  // Auth
  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;
  static bool get isLoggedIn => currentUser != null;

  // Realtime subscription helper
  static RealtimeChannel subscribeToTable({
    required String table,
    required void Function(PostgresChangePayload) onInsert,
    void Function(PostgresChangePayload)? onUpdate,
    void Function(PostgresChangePayload)? onDelete,
  }) {
    return client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          callback: onInsert,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: table,
          callback: onUpdate ?? (_) {},
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: table,
          callback: onDelete ?? (_) {},
        )
        .subscribe();
  }

  // Generic error handler
  static String parseError(dynamic error) {
    if (error is PostgrestException) {
      return error.message;
    }
    return error.toString();
  }
}
