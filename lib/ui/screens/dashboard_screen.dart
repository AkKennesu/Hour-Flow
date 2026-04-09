import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

import '../../logic/viewmodels/time_log_viewmodel.dart';
import '../../logic/viewmodels/settings_viewmodel.dart';
import '../../logic/viewmodels/calendar_event_viewmodel.dart';
import '../../data/models/time_log.dart';
import '../../utils/app_localizations.dart';
import '../../services/notification_service.dart';
import '../widgets/horizontal_date_picker.dart';
import '../widgets/glass_card.dart';

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

  // Load existing log for the selected date if present
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final events = context.read<CalendarEventViewModel>().events;
      if (events.isNotEmpty) {
        NotificationService().checkAndShowInAppNotifications(context, events);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsVm = Provider.of<SettingsViewModel>(context);
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HourFlow',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM yyyy', settingsVm.localeCode).format(_selectedDate),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () {
                    // Trigger sync logic
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: HorizontalDatePicker(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                      _loadLogForDate(date);
                    });
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTimeLogForm(context),
                  const SizedBox(height: 24),
                  _buildDailyTaskLog(context),
                  const SizedBox(height: 24),
                  _buildSubmitButton(context),
                  const SizedBox(height: 80), // bottom padding
                ]),
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
        Text(
          context.tr('today_log'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
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
        Text(
          context.tr('tasks'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: TextField(
            controller: _taskController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: context.tr('what_did_you_do'),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isSaving ? null : _saveLog,
        child: _isSaving 
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                context.tr('save_log'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
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

    // Simulate processing delay for loading state visibility
    await Future.delayed(const Duration(milliseconds: 600));

    // Ensure state context hasn't unmounted before completing async task hook
    if (!mounted) return;

    await context.read<TimeLogViewModel>().saveLog(log);
    
    if (mounted) {
      setState(() => _isSaving = false);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Lottie.network(
                'https://assets9.lottiefiles.com/packages/lf20_lk80fpsm.json', // Checkmark animation
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
          );
        },
      );
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
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white54,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            time != null ? time!.format(context) : '--:--',
            style: theme.textTheme.titleLarge?.copyWith(
              color: time != null ? theme.colorScheme.primary : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
