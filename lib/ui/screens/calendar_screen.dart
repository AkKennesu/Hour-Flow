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
import '../widgets/glass_card.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        child: const Icon(Icons.add_alert),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              title: Text(
                context.tr('log_history'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                          ...vm.logs.where((log) => isSameDay(log.date, day)),
                          ...eventVm.events.where((event) => isSameDay(event.date, day)),
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
                                if (logCount > 0) Container(margin: const EdgeInsets.symmetric(horizontal: 1.5), width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.secondary)),
                                if (eventCount > 0) Container(margin: const EdgeInsets.symmetric(horizontal: 1.5), width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent)),
                              ],
                            ),
                          );
                        },
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: Colors.white70),
                        weekendStyle: TextStyle(color: theme.colorScheme.secondary),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(context.tr('log_summary'), style: theme.textTheme.titleMedium),
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
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(context.tr('no_logs_found'), style: const TextStyle(color: Colors.white54)),
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
                            if (logList.isNotEmpty) const SizedBox(height: 16),
                            ...eventList.map((e) => _EventCard(event: e, vm: eventVm)).toList(),
                          ]
                        ],
                      );
                    }

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: displayWidget,
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
          title: Text(context.tr('new_event'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(labelText: context.tr('event_title')),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(labelText: context.tr('event_desc')),
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
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm, color: Colors.purpleAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: () => vm.deleteEvent(event.id),
              )
            ],
          ),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(event.description, style: const TextStyle(color: Colors.white70)),
          ]
        ],
      )
    );
  }
}

class _HistoricalLogCard extends StatelessWidget {
  final TimeLog log;
  final String localeCode;

  const _HistoricalLogCard({super.key, required this.log, required this.localeCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
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
              Icon(log.isSynchronized ? Icons.cloud_done : Icons.cloud_upload_outlined, size: 16, color: log.isSynchronized ? Colors.green : Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeItem(context.tr('am_in'), log.amIn, theme),
              _buildTimeItem(context.tr('am_out'), log.amOut, theme),
              _buildTimeItem(context.tr('pm_in'), log.pmIn, theme),
              _buildTimeItem(context.tr('pm_out'), log.pmOut, theme),
            ],
          ),
          if (log.tasks != null && log.tasks!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Text(context.tr('tasks'), style: theme.textTheme.labelMedium?.copyWith(color: Colors.white54)),
            const SizedBox(height: 4),
            Text(log.tasks!, style: theme.textTheme.bodyMedium),
          ]
        ],
      ),
    );
  }

  Widget _buildTimeItem(String label, DateTime? time, ThemeData theme) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54)),
        const SizedBox(height: 4),
        Text(
          time != null ? DateFormat('h:mm a').format(time) : '--:--',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
