import 'models.dart';

/// All supplied constraints intersect. Text is a literal, case-insensitive
/// substring of the body; SQL wildcards and habit names have no special meaning.
class JournalQuery {
  const JournalQuery({
    this.month,
    this.day,
    this.habitId,
    this.independent = false,
    this.text = '',
  });
  final Day? month, day;
  final String? habitId;
  final bool independent;
  final String text;
  bool matches(Note note) =>
      (month == null ||
          (month!.date.year == note.day.date.year &&
              month!.date.month == note.day.date.month)) &&
      (day == null || day == note.day) &&
      (habitId == null || habitId == note.habitId) &&
      (!independent || note.habitId == null) &&
      note.body.toLowerCase().contains(text.trim().toLowerCase());
  List<Note> apply(Iterable<Note> notes) {
    final matches = notes.where(this.matches).toList();
    // Stable identity tie-break keeps ordering consistent through backup restore.
    matches.sort((a, b) {
      final date = b.day.compareTo(a.day);
      return date == 0 ? b.id.compareTo(a.id) : date;
    });
    return matches;
  }
}
