import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScannedTimeLog {
  final int? day;
  final DateTime? date;
  final TimeOfDay? amIn;
  final TimeOfDay? amOut;
  final TimeOfDay? pmIn;
  final TimeOfDay? pmOut;
  final TimeOfDay? otIn;
  final TimeOfDay? otOut;

  ScannedTimeLog({
    this.day,
    this.date,
    this.amIn,
    this.amOut,
    this.pmIn,
    this.pmOut,
    this.otIn,
    this.otOut,
  });

  @override
  String toString() => 'Day $day: AM($amIn-$amOut), PM($pmIn-$pmOut), OT($otIn-$otOut)';
}

class TimeCardParser {
  /// Parses [RecognizedText] into a list of [ScannedTimeLog].
  static List<ScannedTimeLog> parse(RecognizedText recognizedText) {
    final List<ScannedTimeLog> logs = [];
    final List<_TextData> timeData = [];
    final List<_TextData> dayData = [];
    DateTime? payEndingDate;

    // 1. Collect all times, potential day numbers, and the pay ending date
    final timeRegex = RegExp(r'(\d{1,2})[:.]([0-5][0-9])\s*([AaPp][Mm])?');
    final dayRegex = RegExp(r'^([1-9]|1[0-5]|1[6-9]|2[0-9]|3[0-1])$'); // Days 1-31
    final dateRegex = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})|([A-Z][a-z]{2})\.?\s+(\d{1,2}),?\s+(\d{4})');

    for (var block in recognizedText.blocks) {
      final blockText = block.text;
      if (blockText.toLowerCase().contains('pay ending')) {
        final match = dateRegex.firstMatch(blockText);
        if (match != null) {
          payEndingDate = _parseDate(match);
        }
      }

      for (var line in block.lines) {
        for (var element in line.elements) {
          final text = element.text.trim();
          
          if (timeRegex.hasMatch(text)) {
            timeData.add(_TextData(element.text, element.boundingBox));
          } else if (dayRegex.hasMatch(text)) {
            dayData.add(_TextData(element.text, element.boundingBox));
          }
        }
      }
    }

    if (timeData.isEmpty) return [];

    // 2. Group times by rows (Y coordinate)
    timeData.sort((a, b) => a.rect.top.compareTo(b.rect.top));
    
    List<List<_TextData>> rows = [];
    if (timeData.isNotEmpty) {
      List<_TextData> currentRow = [timeData[0]];
      for (int i = 1; i < timeData.length; i++) {
        if ((timeData[i].rect.top - currentRow.last.rect.top).abs() < 20) {
          currentRow.add(timeData[i]);
        } else {
          rows.add(currentRow);
          currentRow = [timeData[i]];
        }
      }
      rows.add(currentRow);
    }

    // 3. For each row, identify day and assign times
    for (var row in rows) {
      final rowY = row.map((e) => e.rect.center.dy).reduce((a, b) => a + b) / row.length;
      _TextData? dayElement;
      double minDayDist = double.infinity;
      
      for (var day in dayData) {
        final dist = (day.rect.center.dy - rowY).abs();
        if (dist < minDayDist && dist < 40) {
          minDayDist = dist;
          dayElement = day;
        }
      }

      int? dayNum = dayElement != null ? int.tryParse(dayElement.text) : null;
      if (dayNum == null) continue;

      DateTime? calculatedDate;
      if (payEndingDate != null) {
        // Find the day 15 row to determine the period
        // For a 1-15 card, we assume the pay ending date is the 15th (if found)
        // or we use the dayNum to calculate relative to payEndingDate.
        // A common pattern: Pay Ending is the last day of the card's range.
        // Let's find the max dayNum in the whole card first? 
        // Actually, simplest is: dayNum is the day of month if payEndingDate.day >= dayNum.
        if (payEndingDate.day >= dayNum) {
          calculatedDate = DateTime(payEndingDate.year, payEndingDate.month, dayNum);
        } else {
          // It belongs to the previous month
          final prevMonth = DateTime(payEndingDate.year, payEndingDate.month - 1, dayNum);
          calculatedDate = prevMonth;
        }
      }

      // Chronological fallback for the row (simplest for now)
      final rowTimes = row.map((e) => _parseTime(e.text)).whereType<TimeOfDay>().toList();
      rowTimes.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

      TimeOfDay? amIn, amOut, pmIn, pmOut, otIn, otOut;
      if (rowTimes.isNotEmpty) amIn = rowTimes[0];
      if (rowTimes.length > 1) amOut = rowTimes[1];
      if (rowTimes.length > 2) pmIn = rowTimes[2];
      if (rowTimes.length > 3) pmOut = rowTimes[3];
      if (rowTimes.length > 4) otIn = rowTimes[4];
      if (rowTimes.length > 5) otOut = rowTimes[5];

      logs.add(ScannedTimeLog(
        day: dayNum,
        date: calculatedDate,
        amIn: amIn,
        amOut: amOut,
        pmIn: pmIn,
        pmOut: pmOut,
        otIn: otIn,
        otOut: otOut,
      ));
    }

    return logs;
  }

  static DateTime? _parseDate(RegExpMatch match) {
    try {
      if (match.group(1) != null) {
        // MM/DD/YYYY
        int m = int.parse(match.group(1)!);
        int d = int.parse(match.group(2)!);
        int y = int.parse(match.group(3)!);
        if (y < 100) y += 2000;
        return DateTime(y, m, d);
      } else {
        // MMM DD, YYYY
        final months = {'Jan':1,'Feb':2,'Mar':3,'Apr':4,'May':5,'Jun':6,'Jul':7,'Aug':8,'Sep':9,'Oct':10,'Nov':11,'Dec':12};
        int m = months[match.group(4)] ?? 1;
        int d = int.parse(match.group(5)!);
        int y = int.parse(match.group(6)!);
        return DateTime(y, m, d);
      }
    } catch (_) {
      return null;
    }
  }

  static TimeOfDay? _parseTime(String text) {
    final timeRegex = RegExp(r'(\d{1,2})[:.]([0-5][0-9])\s*([AaPp][Mm])?');
    final match = timeRegex.firstMatch(text);
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    String? ampm = match.group(3)?.toLowerCase();

    if (ampm == 'pm' && hour < 12) hour += 12;
    else if (ampm == 'am' && hour == 12) hour = 0;
    
    return TimeOfDay(hour: hour, minute: minute);
  }
}

class _TextData {
  final String text;
  final Rect rect;
  _TextData(this.text, this.rect);
}
