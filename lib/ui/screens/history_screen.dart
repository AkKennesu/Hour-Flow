import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../logic/viewmodels/time_log_viewmodel.dart';
import '../../data/models/time_log.dart';

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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Card Grid', style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
          ),
          Center(
            child: Text(
              DateFormat('MMM yyyy').format(_currentMonth),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
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
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 470, // Total width of all FixedColumnWidths
                        child: Table(
                          border: TableBorder.all(color: Colors.white24, width: 1, borderRadius: BorderRadius.circular(8)),
                          columnWidths: const {
                            0: FixedColumnWidth(40), // Days
                            1: FixedColumnWidth(60), // AM IN
                            2: FixedColumnWidth(60), // AM OUT
                            3: FixedColumnWidth(60), // PM IN
                            4: FixedColumnWidth(60), // PM OUT
                            5: FixedColumnWidth(60), // OT IN
                            6: FixedColumnWidth(60), // OT OUT
                            7: FixedColumnWidth(70), // Total
                          },
                          children: [
                            _buildHeaderRow(theme),
                            _buildSubHeaderRow(theme),
                            for (int i = 1; i <= daysInMonth; i++)
                              _buildDayRow(DateTime(_currentMonth.year, _currentMonth.month, i), vm, theme),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: const Border(top: BorderSide(color: Colors.white24, width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL MONTHLY ACCUMULATED TIME:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    Text(
                      _formatDuration(monthlyTotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18, 
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  TableRow _buildHeaderRow(ThemeData theme) {
    return TableRow(
      decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.2)),
      children: [
        const _HeaderCell(text: 'Day', isParent: true),
        const _HeaderCell(text: 'MORNING', isParent: true),
        const _HeaderCell(text: '', isParent: false),
        const _HeaderCell(text: 'AFTERNOON', isParent: true),
        const _HeaderCell(text: '', isParent: false),
        const _HeaderCell(text: 'OVERTIME', isParent: true),
        const _HeaderCell(text: '', isParent: false),
        const _HeaderCell(text: 'Daily', isParent: true),
      ],
    );
  }

  TableRow _buildSubHeaderRow(ThemeData theme) {
    return TableRow(
      decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1)),
      children: const [
        _HeaderCell(text: '', isParent: false),
        _HeaderCell(text: 'IN', isParent: false),
        _HeaderCell(text: 'OUT', isParent: false),
        _HeaderCell(text: 'IN', isParent: false),
        _HeaderCell(text: 'OUT', isParent: false),
        _HeaderCell(text: 'IN', isParent: false),
        _HeaderCell(text: 'OUT', isParent: false),
        _HeaderCell(text: 'Total', isParent: false),
      ],
    );
  }

  TableRow _buildDayRow(DateTime date, TimeLogViewModel vm, ThemeData theme) {
    // Check if log exists
    final log = vm.logs.cast<TimeLog?>().firstWhere(
      (l) => l != null && DateUtils.isSameDay(l.date, date), 
      orElse: () => null
    );

    Duration total = Duration.zero;
    if (log != null) {
      total = vm.calculateDailyTotal(log);
    }
    
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final bgOpacity = isToday ? 0.3 : 0.0;
    final bgColor = theme.colorScheme.primary.withOpacity(bgOpacity);

    return TableRow(
      decoration: BoxDecoration(color: bgColor),
      children: [
        InkWell(
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
        title: const Text('Delete Log'),
        content: Text('Are you sure you want to delete all logs for ${DateFormat('MMM d, yyyy').format(log.date)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await vm.deleteLog(log.id);
    }
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes == 0) return '';
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    return '${hours}h ${mins}m';
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool isParent;

  const _HeaderCell({required this.text, required this.isParent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isParent ? 8.0 : 4.0),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isParent ? FontWeight.bold : FontWeight.w600,
            fontSize: isParent ? 11 : 10,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.white,
            fontSize: 12,
          ),
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
    return InkWell(
      onTap: () => _editTime(context),
      onLongPress: log != null ? () => _confirmDeleteRow(context, log!, vm) : null,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        child: Text(
          time != null ? DateFormat('HH:mm').format(time!) : '',
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteRow(BuildContext context, TimeLog log, TimeLogViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log'),
        content: Text('Are you sure you want to delete all logs for ${DateFormat('MMM d, yyyy').format(log.date)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
      
      // Merge into existing log or create a new one
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
