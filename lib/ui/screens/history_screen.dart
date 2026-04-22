import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../logic/viewmodels/time_log_viewmodel.dart';
import '../../logic/viewmodels/settings_viewmodel.dart';
import '../../data/models/time_log.dart';
import '../../utils/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsVm = Provider.of<SettingsViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Card'), 
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
          ),
          Text(
            DateFormat('MMM yyyy', settingsVm.localeCode).format(_currentMonth),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<TimeLogViewModel>(
        builder: (context, vm, child) {
          final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
          final monthlyTotal = vm.calculateMonthlyTotal(_currentMonth.year, _currentMonth.month);
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outline, width: 1.2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Table(
                        border: TableBorder(
                          verticalInside: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5), width: 1),
                          horizontalInside: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
                        ),
                        columnWidths: const {
                          0: FixedColumnWidth(35), // Days
                          1: FlexColumnWidth(1), // AM IN
                          2: FlexColumnWidth(1), // AM OUT
                          3: FlexColumnWidth(1), // PM IN
                          4: FlexColumnWidth(1), // PM OUT
                          5: FlexColumnWidth(1), // OT IN
                          6: FlexColumnWidth(1), // OT OUT
                          7: FixedColumnWidth(65), // HR
                        },
                        children: [
                          _buildHeaderRow(theme, context),
                          _buildSubHeaderRow(theme, context, vm),
                          for (int i = 1; i <= daysInMonth; i++)
                            _buildDayRow(DateTime(_currentMonth.year, _currentMonth.month, i), vm, theme, context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                elevation: 8,
                color: theme.colorScheme.surfaceContainerHigh,
                child: InkWell(
                  onTap: () => _showAccumulatedTimePopup(context, vm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('monthly_total'),
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatDuration(monthlyTotal),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold, 
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  TableRow _buildHeaderRow(ThemeData theme, BuildContext context) {
    return TableRow(
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.3)),
      children: [
        const _HeaderCell(text: '', isParent: true),
        _HeaderCell(text: context.tr('morning').substring(0, 2), isParent: true),
        const _HeaderCell(text: '', isParent: false),
        _HeaderCell(text: context.tr('afternoon').substring(0, 2), isParent: true),
        const _HeaderCell(text: '', isParent: false),
        const _HeaderCell(text: 'OT', isParent: true),
        const _HeaderCell(text: '', isParent: false),
        const _HeaderCell(text: 'HR', isParent: true), // Replaced DAILY with HR
      ],
    );
  }

  TableRow _buildSubHeaderRow(ThemeData theme, BuildContext context, TimeLogViewModel vm) {
    return TableRow(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer),
      children: [
        const _HeaderCell(text: '#', isParent: false),
        _HeaderCell(
          text: 'IN', 
          isParent: false,
          onTap: () => _batchEdit(context, 'amIn', vm),
        ),
        _HeaderCell(
          text: 'OUT', 
          isParent: false,
          onTap: () => _batchEdit(context, 'amOut', vm),
        ),
        _HeaderCell(
          text: 'IN', 
          isParent: false,
          onTap: () => _batchEdit(context, 'pmIn', vm),
        ),
        _HeaderCell(
          text: 'OUT', 
          isParent: false,
          onTap: () => _batchEdit(context, 'pmOut', vm),
        ),
        _HeaderCell(
          text: 'IN', 
          isParent: false,
          onTap: () => _batchEdit(context, 'otIn', vm),
        ),
        _HeaderCell(
          text: 'OUT', 
          isParent: false,
          onTap: () => _batchEdit(context, 'otOut', vm),
        ),
        const _HeaderCell(text: 'Σ', isParent: false),
      ],
    );
  }

  Future<void> _batchEdit(BuildContext context, String field, TimeLogViewModel vm) async {
    final picked = await showTimePicker(
      context: context, 
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'BATCH EDIT ${field.toUpperCase()}',
    );
    
    if (picked == null) return;

    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final List<TimeLog> updatedLogs = [];

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, i);
      final log = vm.logs.cast<TimeLog?>().firstWhere(
        (l) => l != null && DateUtils.isSameDay(l.date, date),
        orElse: () => null
      );

      final updatedTime = DateTime(date.year, date.month, date.day, picked.hour, picked.minute);
      
      TimeLog updatedLog = log ?? TimeLog(
        id: DateFormat('yyyy-MM-dd').format(date),
        date: date,
      );

      updatedLog = updatedLog.copyWith(
        amIn: field == 'amIn' ? updatedTime : updatedLog.amIn,
        amOut: field == 'amOut' ? updatedTime : updatedLog.amOut,
        pmIn: field == 'pmIn' ? updatedTime : updatedLog.pmIn,
        pmOut: field == 'pmOut' ? updatedTime : updatedLog.pmOut,
        otIn: field == 'otIn' ? updatedTime : updatedLog.otIn,
        otOut: field == 'otOut' ? updatedTime : updatedLog.otOut,
      );
      
      updatedLogs.add(updatedLog);
    }

    await vm.saveLogs(updatedLogs);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated $field for the whole month')),
      );
    }
  }

  TableRow _buildDayRow(DateTime date, TimeLogViewModel vm, ThemeData theme, BuildContext context) {
    final log = vm.logs.cast<TimeLog?>().firstWhere(
      (l) => l != null && DateUtils.isSameDay(l.date, date), 
      orElse: () => null
    );

    Duration total = Duration.zero;
    if (log != null) {
      total = vm.calculateDailyTotal(log);
    }
    
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final bgColor = isToday ? theme.colorScheme.primaryContainer.withOpacity(0.2) : null;

    return TableRow(
      decoration: BoxDecoration(
        color: bgColor,
      ),
      children: [
        InkWell(
          onTap: log != null ? () => _showTasksPopup(context, log) : null,
          onLongPress: log != null ? () => _confirmDeleteRow(context, log, vm) : null,
          child: _TableCellContainer(text: '${date.day}', isBold: true),
        ),
        _TimeCell(date: date, time: log?.amIn, field: 'amIn', log: log, vm: vm),
        _TimeCell(date: date, time: log?.amOut, field: 'amOut', log: log, vm: vm),
        _TimeCell(date: date, time: log?.pmIn, field: 'pmIn', log: log, vm: vm),
        _TimeCell(date: date, time: log?.pmOut, field: 'pmOut', log: log, vm: vm),
        _TimeCell(date: date, time: log?.otIn, field: 'otIn', log: log, vm: vm),
        _TimeCell(date: date, time: log?.otOut, field: 'otOut', log: log, vm: vm),
        _TableCellContainer(text: _formatDuration(total), isBold: true, color: theme.colorScheme.secondary),
      ],
    );
  }

  Future<void> _confirmDeleteRow(BuildContext context, TimeLog log, TimeLogViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_log')),
        content: Text('${context.tr('delete_confirm')}${DateFormat('MMM d, yyyy').format(log.date)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(context.tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await vm.deleteLog(log.id);
    }
  }

  void _showTasksPopup(BuildContext context, TimeLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${context.tr('tasks')} ${DateFormat('MMM d, yyyy').format(log.date)}'),
        content: Text(log.tasks ?? context.tr('no_logs_found')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
        ],
      ),
    );
  }

  void _showAccumulatedTimePopup(BuildContext context, TimeLogViewModel vm) {
    final Map<DateTime, Duration> rawMonthlyTotals = {};
    Duration grandTotal = Duration.zero;

    for (var log in vm.logs) {
      final monthKey = DateTime(log.date.year, log.date.month);
      final dailyTotal = vm.calculateDailyTotal(log);
      rawMonthlyTotals[monthKey] = (rawMonthlyTotals[monthKey] ?? Duration.zero) + dailyTotal;
      grandTotal += dailyTotal;
    }

    final sortedMonths = rawMonthlyTotals.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('log_summary')),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedMonths.length,
                  itemBuilder: (context, index) {
                    final monthDate = sortedMonths[index];
                    final total = rawMonthlyTotals[monthDate]!;
                    return ListTile(
                      title: Text(DateFormat('MMMM yyyy').format(monthDate)),
                      trailing: Text(_formatDuration(total), style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('GRAND TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  _formatDuration(grandTotal),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes == 0) return '-';
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    return '${hours}h${mins}m';
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool isParent;
  final VoidCallback? onTap;

  const _HeaderCell({required this.text, required this.isParent, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isParent ? 12.0 : 8.0, horizontal: 2.0),
        child: Center(
          child: Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isParent ? 12 : 10,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _TableCellContainer extends StatelessWidget {
  final String text;
  final bool isBold;
  final Color? color;

  const _TableCellContainer({required this.text, this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      alignment: Alignment.center,
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? theme.colorScheme.onSurface,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  final DateTime date;
  final DateTime? time;
  final String field;
  final TimeLog? log;
  final TimeLogViewModel vm;

  const _TimeCell({
    required this.date,
    required this.time,
    required this.field,
    required this.log,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _editTime(context),
      onLongPress: log != null ? () => _confirmDeleteRow(context, log!, vm) : null,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        child: Text(
          time != null ? DateFormat('HH:mm').format(time!) : '',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12, 
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteRow(BuildContext context, TimeLog log, TimeLogViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_log')),
        content: Text('${context.tr('delete_confirm')}${DateFormat('MMM d, yyyy').format(log.date)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(context.tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await vm.deleteLog(log.id);
    }
  }

  Future<void> _editTime(BuildContext context) async {
    final TimeOfDay initial = time != null 
        ? TimeOfDay.fromDateTime(time!) 
        : TimeOfDay.now();

    final picked = await showTimePicker(context: context, initialTime: initial);
    
    if (picked != null) {
      final updatedTime = DateTime(date.year, date.month, date.day, picked.hour, picked.minute);
      
      TimeLog updatedLog = log ?? TimeLog(
        id: DateFormat('yyyy-MM-dd').format(date),
        date: date,
      );

      updatedLog = updatedLog.copyWith(
        amIn: field == 'amIn' ? updatedTime : null,
        amOut: field == 'amOut' ? updatedTime : null,
        pmIn: field == 'pmIn' ? updatedTime : null,
        pmOut: field == 'pmOut' ? updatedTime : null,
        otIn: field == 'otIn' ? updatedTime : null,
        otOut: field == 'otOut' ? updatedTime : null,
      );

      await vm.saveLog(updatedLog);
    }
  }
}
