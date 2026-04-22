import 'package:flutter/material.dart';
import '../../utils/time_card_parser.dart';
import '../../utils/app_localizations.dart';

class ScanReviewScreen extends StatefulWidget {
  final List<ScannedTimeLog> scannedLogs;
  final String imagePath;

  const ScanReviewScreen({
    super.key,
    required this.scannedLogs,
    required this.imagePath,
  });

  @override
  State<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends State<ScanReviewScreen> {
  late List<ScannedTimeLog> _logs;

  @override
  void initState() {
    super.initState();
    _logs = List.from(widget.scannedLogs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Scan'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  log.day != null ? 'DAY ${log.day}' : 'DAY ??',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (log.date != null) 
                                Text(
                                  'Detected Date: ${log.date!.day}/${log.date!.month}',
                                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildReviewGrid(context, log, index),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Pop review
                  Navigator.pop(context, _logs); // Pop scanner with results
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Apply All to History'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewGrid(BuildContext context, ScannedTimeLog log, int index) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildReviewItem(context, context.tr('am_in'), log.amIn, (t) => setState(() => _logs[index] = _updateLog(log, amIn: t)))),
            const SizedBox(width: 12),
            Expanded(child: _buildReviewItem(context, context.tr('am_out'), log.amOut, (t) => setState(() => _logs[index] = _updateLog(log, amOut: t)))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildReviewItem(context, context.tr('pm_in'), log.pmIn, (t) => setState(() => _logs[index] = _updateLog(log, pmIn: t)))),
            const SizedBox(width: 12),
            Expanded(child: _buildReviewItem(context, context.tr('pm_out'), log.pmOut, (t) => setState(() => _logs[index] = _updateLog(log, pmOut: t)))),
          ],
        ),
        if (log.otIn != null || log.otOut != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildReviewItem(context, 'OT IN', log.otIn, (t) => setState(() => _logs[index] = _updateLog(log, otIn: t)))),
              const SizedBox(width: 12),
              Expanded(child: _buildReviewItem(context, 'OT OUT', log.otOut, (t) => setState(() => _logs[index] = _updateLog(log, otOut: t)))),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildReviewItem(BuildContext context, String title, TimeOfDay? time, Function(TimeOfDay?) onChanged) {
    final theme = Theme.of(context);
    final bool hasTime = time != null;

    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? const TimeOfDay(hour: 8, minute: 0),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasTime ? theme.colorScheme.primaryContainer.withOpacity(0.3) : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasTime ? theme.colorScheme.primary.withOpacity(0.2) : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(
              hasTime ? time!.format(context) : 'Empty',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: hasTime ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ScannedTimeLog _updateLog(ScannedTimeLog old, {TimeOfDay? amIn, TimeOfDay? amOut, TimeOfDay? pmIn, TimeOfDay? pmOut, TimeOfDay? otIn, TimeOfDay? otOut}) {
    return ScannedTimeLog(
      day: old.day,
      date: old.date,
      amIn: amIn ?? old.amIn,
      amOut: amOut ?? old.amOut,
      pmIn: pmIn ?? old.pmIn,
      pmOut: pmOut ?? old.pmOut,
      otIn: otIn ?? old.otIn,
      otOut: otOut ?? old.otOut,
    );
  }
}
