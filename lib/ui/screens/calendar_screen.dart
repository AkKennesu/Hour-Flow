import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../logic/viewmodels/time_log_viewmodel.dart';
import '../../logic/viewmodels/settings_viewmodel.dart';
import '../../logic/viewmodels/calendar_event_viewmodel.dart';
import '../../data/models/time_log.dart';
import '../../data/models/calendar_event.dart';
import '../../utils/app_localizations.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsVm = Provider.of<SettingsViewModel>(context);
    
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventDialog(context),
        icon: const Icon(Icons.add_alert_rounded),
        label: Text(context.tr('new_event')),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(context.tr('calendar'), style: theme.appBarTheme.titleTextStyle),
              centerTitle: true,
              floating: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Consumer2<TimeLogViewModel, CalendarEventViewModel>(
                  builder: (context, vm, eventVm, child) {
                    return TableCalendar(
                      locale: settingsVm.localeCode,
                      firstDay: DateTime.utc(2020, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        if (!isSameDay(_selectedDay, selectedDay)) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      eventLoader: (day) {
                        return [
                          ...vm.logs.whereType<TimeLog>().where((log) => isSameDay(log.date, day)),
                          ...eventVm.events.whereType<CalendarEvent>().where((event) => isSameDay(event.date, day)),
                        ];
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return const SizedBox();
                          
                          int logCount = events.whereType<TimeLog>().length;
                          int eventCount = events.whereType<CalendarEvent>().length;
                          
                          return Positioned(
                            bottom: 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (logCount > 0) Container(margin: const EdgeInsets.symmetric(horizontal: 1.5), width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary)),
                                if (eventCount > 0) Container(margin: const EdgeInsets.symmetric(horizontal: 1.5), width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.secondary)),
                              ],
                            ),
                          );
                        },
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                        selectedDecoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
                        markerDecoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                        leftChevronIcon: const Icon(Icons.chevron_left_rounded),
                        rightChevronIcon: const Icon(Icons.chevron_right_rounded),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                        weekendStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text(
                  context.tr('log_summary'), 
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Consumer2<TimeLogViewModel, CalendarEventViewModel>(
                  builder: (context, viewModel, eventVm, child) {
                    final logList = viewModel.logs.where((log) => isSameDay(log.date, _selectedDay)).toList();
                    final eventList = eventVm.events.where((event) => isSameDay(event.date, _selectedDay)).toList();
                    final Widget displayWidget;

                    if (logList.isEmpty && eventList.isEmpty) {
                      displayWidget = Padding(
                        key: const ValueKey('empty'),
                        padding: const EdgeInsets.all(40.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.event_busy_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(
                                context.tr('no_logs_found'), 
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      displayWidget = Column(
                        key: ValueKey(_selectedDay?.toIso8601String() ?? 'items'),
                        children: [
                          if (logList.isNotEmpty)
                            _HistoricalLogCard(
                              log: logList.first,
                              localeCode: settingsVm.localeCode,
                            ),
                          if (eventList.isNotEmpty) ...[
                            if (logList.isNotEmpty) const SizedBox(height: 12),
                            ...eventList.map((e) => _EventCard(event: e, vm: eventVm)).toList(),
                          ]
                        ],
                      );
                    }

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: displayWidget,
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEventDialog(BuildContext context) async {
    if (_selectedDay == null || _selectedDay!.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a future date first.')));
      return;
    }

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr('new_event')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: context.tr('event_title'),
                  hintText: 'e.g., Client Meeting',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: context.tr('event_desc'),
                  hintText: 'Add details here...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                final newEvent = CalendarEvent(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: _selectedDay!,
                  title: titleCtrl.text,
                  description: descCtrl.text,
                );
                await context.read<CalendarEventViewModel>().saveEvent(newEvent);
                if (mounted) Navigator.pop(context);
              },
              child: Text(context.tr('add')),
            )
          ],
        );
      }
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final CalendarEventViewModel vm;

  const _EventCard({required this.event, required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.notifications_active_rounded, color: theme.colorScheme.onSecondaryContainer, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    event.title, 
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 20),
                  onPressed: () => vm.deleteEvent(event.id),
                )
              ],
            ),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Text(
                  event.description, 
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _HistoricalLogCard extends StatelessWidget {
  final TimeLog log;
  final String localeCode;

  const _HistoricalLogCard({required this.log, required this.localeCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d, yyyy - EEEE', localeCode).format(log.date),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Icon(
                log.isSynchronized ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, 
                size: 18, 
                color: log.isSynchronized ? Colors.green : theme.colorScheme.outline,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeItem(context.tr('am_in'), log.amIn, theme),
              _buildTimeItem(context.tr('am_out'), log.amOut, theme),
              _buildTimeItem(context.tr('pm_in'), log.pmIn, theme),
              _buildTimeItem(context.tr('pm_out'), log.pmOut, theme),
            ],
          ),
          if (log.tasks != null && log.tasks!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              context.tr('tasks'), 
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(log.tasks!, style: theme.textTheme.bodyLarge),
          ]
        ],
      ),
      ),
    );
  }

  Widget _buildTimeItem(String label, DateTime? time, ThemeData theme) {
    return Column(
      children: [
        Text(
          label, 
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(
          time != null ? DateFormat('h:mm a').format(time) : '--:--',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
