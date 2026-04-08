import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../logic/viewmodels/time_log_viewmodel.dart';
import '../../data/models/time_log.dart';
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
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              title: Text(
                'Log History',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Consumer<TimeLogViewModel>(
                  builder: (context, vm, child) {
                    return TableCalendar(
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
                        return vm.logs.where((log) => isSameDay(log.date, day)).toList();
                      },
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
                child: Text('Log Summary', style: theme.textTheme.titleMedium),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Consumer<TimeLogViewModel>(
                  builder: (context, viewModel, child) {
                    final logList = viewModel.logs.where((log) => isSameDay(log.date, _selectedDay)).toList();
                    final Widget displayWidget;

                    if (logList.isEmpty) {
                      displayWidget = const Padding(
                        key: ValueKey('empty'),
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text('No logs found for this day.', style: TextStyle(color: Colors.white54)),
                        ),
                      );
                    } else {
                      displayWidget = _HistoricalLogCard(
                        key: ValueKey(logList.first.id),
                        log: logList.first,
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
}

class _HistoricalLogCard extends StatelessWidget {
  final TimeLog log;

  const _HistoricalLogCard({super.key, required this.log});

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
                DateFormat('MMM d, yyyy - EEEE').format(log.date),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Icon(log.isSynchronized ? Icons.cloud_done : Icons.cloud_upload_outlined, size: 16, color: log.isSynchronized ? Colors.green : Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeItem('AM IN', log.amIn, theme),
              _buildTimeItem('AM OUT', log.amOut, theme),
              _buildTimeItem('PM IN', log.pmIn, theme),
              _buildTimeItem('PM OUT', log.pmOut, theme),
            ],
          ),
          if (log.tasks != null && log.tasks!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Text('Tasks:', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white54)),
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
