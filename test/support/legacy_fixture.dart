import 'package:daypanel/domain/models.dart';

Map<String, Object?> legacyFixture({int version = 25, bool rolling = false}) {
  final day = Day.parse('2026-11-06');
  int stamp(int offset) => DateTime.utc(
    day.plus(offset).date.year,
    day.plus(offset).date.month,
    day.plus(offset).date.day,
  ).millisecondsSinceEpoch;
  Map<String, Object?> habit(int id, String name, int type) => {
    'id': id,
    'name': name,
    'type': type,
    'target_type': 0,
    'target': type == 1 ? '2000.0' : '1.0',
    'unit': type == 1 ? 'ml' : '',
    'numerator': rolling && id == 1 ? 2 : 1,
    'denominator': rolling && id == 1 ? 3 : 1,
    'archived': 0,
    'position': id,
    'description': 'Source description',
    'question': version >= 23 ? 'Source question' : '',
    'uuid': version >= 24 ? 'source-uuid-$id' : '',
  };
  return {
    'version': version,
    'habits': [habit(1, 'Old reading', 0), habit(2, 'Old water', 1)],
    'entries': [
      for (final pair in [(-5, 2), (-4, 0), (-3, 1), (-2, 3), (-1, -1)])
        {
          'habit': 1,
          'timestamp': stamp(pair.$1),
          'value': pair.$2,
          'notes': version >= 25 && pair.$1 == -2 ? 'Rest day' : '',
        },
      {
        'habit': 2,
        'timestamp': stamp(-1),
        'value': 250001,
        'notes': version >= 25 ? 'A small glass' : '',
      },
      {'habit': 2, 'timestamp': stamp(0), 'value': 0, 'notes': ''},
    ],
  };
}
