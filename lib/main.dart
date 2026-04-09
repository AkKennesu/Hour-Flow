import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/notification_service.dart';
import 'ui/theme/app_theme.dart';
import 'router/app_router.dart';
import 'data/services/database_service.dart';
import 'data/repositories/time_log_repository.dart';
import 'logic/viewmodels/time_log_viewmodel.dart';
import 'logic/viewmodels/settings_viewmodel.dart';
import 'logic/viewmodels/calendar_event_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await NotificationService().init();
  
  await Hive.initFlutter();
  final dbService = DatabaseService();
  await dbService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TimeLogViewModel(TimeLogRepository(dbService)),
        ),
        ChangeNotifierProvider(
          create: (_) => CalendarEventViewModel(dbService),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(),
        ),
      ],
      child: const HourFlowApp(),
    ),
  );
}

class HourFlowApp extends StatelessWidget {
  const HourFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HourFlow',
      themeMode: ThemeMode.system, // Responsive to system
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
