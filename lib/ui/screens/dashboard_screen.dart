import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../logic/viewmodels/time_log_viewmodel.dart';
import '../../logic/viewmodels/settings_viewmodel.dart';
import '../../data/models/time_log.dart';
import '../../utils/app_localizations.dart';
import '../widgets/horizontal_date_picker.dart';
import 'camera_scan_screen.dart';
import '../../utils/time_card_parser.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _amIn;
  TimeOfDay? _amOut;
  TimeOfDay? _pmIn;
  TimeOfDay? _pmOut;
  final TextEditingController _taskController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _loadLogForDate(DateTime date) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<TimeLogViewModel>();
      final existingLog = vm.logs.cast<TimeLog?>().firstWhere(
            (log) => log != null && DateUtils.isSameDay(log.date, date),
            orElse: () => null,
          );
      
      setState(() {
        if (existingLog != null) {
          _amIn = existingLog.amIn != null ? TimeOfDay.fromDateTime(existingLog.amIn!) : null;
          _amOut = existingLog.amOut != null ? TimeOfDay.fromDateTime(existingLog.amOut!) : null;
          _pmIn = existingLog.pmIn != null ? TimeOfDay.fromDateTime(existingLog.pmIn!) : null;
          _pmOut = existingLog.pmOut != null ? TimeOfDay.fromDateTime(existingLog.pmOut!) : null;
          _taskController.text = existingLog.tasks ?? '';
        } else {
          _amIn = null; _amOut = null; _pmIn = null; _pmOut = null;
          _taskController.clear();
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _loadLogForDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsVm = Provider.of<SettingsViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('WorkFlow', style: theme.appBarTheme.titleTextStyle),
            Text(
              DateFormat('MMMM yyyy', settingsVm.localeCode).format(_selectedDate),
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            onPressed: () => _navigateToScanner(context),
            tooltip: 'Scan Time Card',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            HorizontalDatePicker(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                  _loadLogForDate(date);
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeLogForm(context),
                  const SizedBox(height: 24),
                  _buildDailyTaskLog(context),
                  const SizedBox(height: 32),
                  _buildSubmitButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeLogForm(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            context.tr('today_log'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            Expanded(child: _TimeInputCard(title: context.tr('am_in'), time: _amIn, onTap: () => _pickTime(context, 'amIn'))),
            const SizedBox(width: 12),
            Expanded(child: _TimeInputCard(title: context.tr('am_out'), time: _amOut, onTap: () => _pickTime(context, 'amOut'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _TimeInputCard(title: context.tr('pm_in'), time: _pmIn, onTap: () => _pickTime(context, 'pmIn'))),
            const SizedBox(width: 12),
            Expanded(child: _TimeInputCard(title: context.tr('pm_out'), time: _pmOut, onTap: () => _pickTime(context, 'pmOut'))),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyTaskLog(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            context.tr('tasks'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        TextField(
          controller: _taskController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: context.tr('what_did_you_do'),
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: _isSaving ? null : _saveLog,
      icon: _isSaving 
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.save_rounded, size: 20),
      label: Text(context.tr('save_log')),
    );
  }

  Future<void> _navigateToScanner(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScanScreen()),
    );

    if (result != null && result is List<ScannedTimeLog> && result.isNotEmpty) {
      final logs = result;
      final timeLogVm = context.read<TimeLogViewModel>();
      
      final today = DateTime.now();
      ScannedTimeLog? todayScanned = logs.cast<ScannedTimeLog?>().firstWhere(
        (l) => l?.date != null && DateUtils.isSameDay(l!.date!, today),
        orElse: () => null,
      );

      todayScanned ??= logs.last; 

      setState(() {
        if (todayScanned?.amIn != null) _amIn = todayScanned!.amIn;
        if (todayScanned?.amOut != null) _amOut = todayScanned!.amOut;
        if (todayScanned?.pmIn != null) _pmIn = todayScanned!.pmIn;
        if (todayScanned?.pmOut != null) _pmOut = todayScanned!.pmOut;
      });

      int savedCount = 0;
      for (var sLog in logs) {
        if (sLog.date != null) {
          final timeLog = TimeLog(
            id: DateFormat('yyyy-MM-dd').format(sLog.date!),
            date: sLog.date!,
            amIn: _combine(sLog.date!, sLog.amIn),
            amOut: _combine(sLog.date!, sLog.amOut),
            pmIn: _combine(sLog.date!, sLog.pmIn),
            pmOut: _combine(sLog.date!, sLog.pmOut),
            otIn: _combine(sLog.date!, sLog.otIn),
            otOut: _combine(sLog.date!, sLog.otOut),
            isSynchronized: false,
          );
          await timeLogVm.saveLog(timeLog);
          savedCount++;
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(savedCount > 0 
              ? 'Saved $savedCount days from scan' 
              : 'Today\'s times updated from scan'),
          ),
        );
      }
    }
  }

  Future<void> _pickTime(BuildContext context, String field) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (field == 'amIn') _amIn = picked;
        if (field == 'amOut') _amOut = picked;
        if (field == 'pmIn') _pmIn = picked;
        if (field == 'pmOut') _pmOut = picked;
      });
    }
  }

  DateTime? _combine(DateTime date, TimeOfDay? time) {
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _saveLog() async {
    setState(() => _isSaving = true);

    final log = TimeLog(
      id: DateFormat('yyyy-MM-dd').format(_selectedDate),
      date: _selectedDate,
      amIn: _combine(_selectedDate, _amIn),
      amOut: _combine(_selectedDate, _amOut),
      pmIn: _combine(_selectedDate, _pmIn),
      pmOut: _combine(_selectedDate, _pmOut),
      tasks: _taskController.text.trim(),
      isSynchronized: false,
    );

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      await context.read<TimeLogViewModel>().saveLog(log);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Lottie.network(
                'https://assets9.lottiefiles.com/packages/lf20_lk80fpsm.json',
                repeat: false,
                onLoaded: (composition) {
                  Future.delayed(composition.duration, () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  });
                },
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving log: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _TimeInputCard extends StatelessWidget {
  final String title;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimeInputCard({
    required this.title,
    this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = time != null;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                time != null ? time!.format(context) : '--:--',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
