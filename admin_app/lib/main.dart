import 'package:flutter/material.dart';
import 'package:admin_app/core/db/isar_service.dart';
import 'package:admin_app/core/services/cache_refresh_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/delivery_label_print_service.dart';
import 'package:admin_app/app.dart';

/// App lifecycle handler to manage print polling
class AppLifecycleHandler extends WidgetsBindingObserver {
  final VoidCallback onResume;
  final Future<void> Function() onPause;

  AppLifecycleHandler({
    required this.onResume,
    required this.onPause,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('[PRINT_QUEUE][ADMIN] App resumed - starting poll');
        onResume();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        debugPrint('[PRINT_QUEUE][ADMIN] App paused - stopping poll');
        onPause();
        break;
      case AppLifecycleState.hidden:
        // Hidden is similar to paused - stop polling
        debugPrint('[PRINT_QUEUE][ADMIN] App hidden - stopping poll');
        onPause();
        break;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Blueprint: Supabase initialized ONCE, only in SupabaseService
  await SupabaseService.initialize();

  // Offline: Isar opened once; all collections registered in IsarService
  await IsarService.init();

  // When connectivity goes online, refresh inventory and categories cache in background
  CacheRefreshService().start();

  // Set up lifecycle handler for print polling
  final lifecycleHandler = AppLifecycleHandler(
    onResume: () {
      DeliveryLabelPrintService.instance.startPolling();
    },
    onPause: () async {
      DeliveryLabelPrintService.instance.stopPolling();
    },
  );

  // Register the lifecycle observer
  WidgetsBinding.instance.addObserver(lifecycleHandler);

  // Start delivery label print polling
  DeliveryLabelPrintService.instance.startPolling();

  runApp(const AdminApp());
}
