import '../models/listen_entry.dart';
import '../models/memory.dart';

/// Something from this date in an earlier year: one of his memories, or else
/// a song she played.
class OnThisDay {
  final int yearsAgo;
  final Memory? memory;
  final ListenEntry? entry;

  const OnThisDay({required this.yearsAgo, this.memory, this.entry});
}

/// What happened on [today]'s date in an earlier year, or null when nothing
/// did. His memories come first, since they are his words; the most recent
/// year wins when there are several. Only earlier years count, so something
/// from today never shows up as "a year ago".
OnThisDay? pickOnThisDay(
  DateTime today, {
  required List<Memory> memories,
  required List<ListenEntry> entries,
}) {
  bool earlierYear(DateTime date) =>
      date.month == today.month &&
      date.day == today.day &&
      date.year < today.year;

  final remembered = memories.where((m) => earlierYear(m.date)).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  if (remembered.isNotEmpty) {
    final memory = remembered.first;
    return OnThisDay(yearsAgo: today.year - memory.date.year, memory: memory);
  }

  final played = entries.where((e) => earlierYear(e.playedAt)).toList()
    ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
  if (played.isNotEmpty) {
    final entry = played.first;
    return OnThisDay(yearsAgo: today.year - entry.playedAt.year, entry: entry);
  }
  return null;
}
