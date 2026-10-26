import 'memory.dart';

/// What he says about the two of them: since when, and when they next meet.
class Together {
  final DateTime? since;
  final DateTime? meetingDate;

  /// What he calls the countdown. Empty means the usual words.
  final String meetingLabel;

  const Together({this.since, this.meetingDate, this.meetingLabel = ''});

  static const none = Together();

  factory Together.parse(Object? json) {
    if (json is! Map) return none;
    final Map<dynamic, dynamic> map = json;

    String text(String key) {
      final value = map[key];
      return value is String ? value.trim() : '';
    }

    return Together(
      since: Memory.parseDate(text('since')),
      meetingDate: Memory.parseDate(text('meetingDate')),
      meetingLabel: text('meetingLabel'),
    );
  }

  /// Whole days from [today] to the day they meet: 0 on the day itself.
  /// Null when there is no meeting day, or it has passed.
  int? daysUntilMeeting(DateTime today) {
    final meeting = meetingDate;
    if (meeting == null) return null;
    // Both as plain days, so a clock change never moves the count.
    final from = DateTime.utc(today.year, today.month, today.day);
    final to = DateTime.utc(meeting.year, meeting.month, meeting.day);
    final days = to.difference(from).inDays;
    return days < 0 ? null : days;
  }
}
