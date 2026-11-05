import 'package:flutter_test/flutter_test.dart';
import 'package:daypanel/domain/models.dart';

void main() {
  test('quantity preserves thousandths without floating point', () {
    expect(parseQuantity('0.001'), 1);
    expect(parseQuantity('250.025'), 250025);
    expect(parseQuantity('1,5'), 1500);
    expect(quantityText(250025), '250.025');
    expect(quantityText(1000), '1');
    expect(quantityText(0), '0');
  });
  test(
    'quantity rejects negative, non-finite, excess precision and grouping',
    () {
      for (final invalid in [
        '-1',
        'NaN',
        'Infinity',
        '1e6',
        '1.0001',
        '1,000.50',
        '',
        '1000000000',
      ]) {
        expect(parseQuantity(invalid), isNull, reason: invalid);
      }
    },
  );
  test('local calendar arithmetic crosses month and leap day', () {
    expect(Day(DateTime(2028, 2, 28, 23, 50)).plus(1).key, '2028-02-29');
    expect(Day(DateTime(2028, 2, 29)).plus(1).key, '2028-03-01');
    expect(Day(DateTime(2026, 12, 31)).plus(1).key, '2027-01-01');
  });
  test('weekly schedule respects actual weekday, start and archive', () {
    final h = Habit(
      id: 'a',
      title: 'Read',
      kind: HabitKind.check,
      startDay: Day.parse('2026-11-05'),
      weekdays: 1,
    );
    expect(h.scheduled(Day.parse('2026-11-02')), isFalse);
    expect(h.scheduled(Day.parse('2026-11-09')), isTrue);
    expect(h.scheduled(Day.parse('2026-11-10')), isFalse);
    final archived = Habit.fromMap({...h.toMap(), 'archived': 1});
    expect(archived.scheduled(Day.parse('2026-11-09')), isFalse);
  });
}
