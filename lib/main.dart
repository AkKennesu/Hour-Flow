import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';

import 'services/notification_service.dart';
import 'ui/theme/app_theme.dart';
import 'router/app_router.dart';
import 'data/services/database_service.dart';
import 'data/repositories/time_log_repository.dart';
import 'logic/viewmodels/auth_viewmodel.dart';
import 'logic/viewmodels/time_log_viewmodel.dart';
import 'logic/viewmodels/settings_viewmodel.dart';
import 'logic/viewmodels/calendar_event_viewmodel.dart';
import 'services/cloud_sync_service.dart';
import 'services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await NotificationService().init();
  
  await Hive.initFlutter();
  final dbService = DatabaseService();
  await dbService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => CloudSyncService()),
        Provider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, TimeLogViewModel>(
          create: (context) => TimeLogViewModel(
            TimeLogRepository(dbService),
            context.read<CloudSyncService>(),
            context.read<ConnectivityService>(),
          ),
          update: (context, auth, previous) {
            if (auth.isAuthenticated) {
              dbService.openUserBoxes(auth.user!.uid).then((_) {
                previous?.loadLogs();
              });
            } else {
              dbService.closeUserBoxes();
            }
            return previous!;
          },
        ),
        ChangeNotifierProxyProvider<AuthViewModel, CalendarEventViewModel>(
          create: (context) => CalendarEventViewModel(
            dbService,
            context.read<CloudSyncService>(),
            context.read<ConnectivityService>(),
          ),
          update: (context, auth, previous) {
            if (auth.isAuthenticated) {
              dbService.openUserBoxes(auth.user!.uid).then((_) {
                previous?.loadEvents();
              });
            }
            return previous!;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(),
        ),
      ],
      child: const HourFlowApp(),
    ),
  );
}

class HourFlowApp extends StatefulWidget {
  const HourFlowApp({super.key});

  @override
  State<HourFlowApp> createState() => _HourFlowAppState();
}

class _HourFlowAppState extends State<HourFlowApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create the router only once
    final authViewModel = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(authViewModel);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    return MaterialApp.router(
      title: 'WorkFlow',
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
