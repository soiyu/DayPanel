part of 'app_store.dart';

extension StoreCards on AppStore {
  Future<List<AchievementCard>> cards() async => (await db.query(
    'cards',
    orderBy: 'day DESC',
  )).map(AchievementCard.fromMap).toList();

  Future<void> claimCard(Day day, {required Day today}) async {
    if (day != today) throw ArgumentError('Only today can be claimed');
    await db.transaction((txn) async {
      if (await earnCardIn(txn, day) == null) {
        throw StateError('Daily plan is not complete');
      }
    });
  }

  Future<AchievementCard?> earnCardIn(DatabaseExecutor txn, Day day) async {
    final saved = await txn.query(
      'cards',
      where: 'day=?',
      whereArgs: [day.key],
    );
    if (saved.isNotEmpty) return AchievementCard.fromMap(saved.single);
    final habits = (await txn.query(
      'habits',
      orderBy: 'position,id',
    )).map(Habit.fromMap).toList();
    final plans = (await txn.query(
      'plans',
      orderBy: 'effective_day',
    )).map(HabitPlan.fromMap).toList();
    final entries =
        (await txn.query('entries', where: 'day=?', whereArgs: [day.key]))
            .map(
              (m) => HabitEntry(
                habitId: m['habit_id'] as String,
                day: day,
                value: m['value'] as int,
              ),
            )
            .toList();
    final evidence = completedCardEvidence(day, habits, plans, entries);
    if (evidence == null) return null;
    final card = AchievementCard(
      day: day,
      artwork: AchievementCard.artworkFor(day),
      evidence: evidence,
    );
    final validated = AchievementCard.fromMap(card.toMap());
    await txn.insert('cards', validated.toMap());
    return card;
  }

  Future<void> favoriteCard(Day day, bool favorite) async {
    if (await db.update(
          'cards',
          {'favorite': favorite ? 1 : 0},
          where: 'day=?',
          whereArgs: [day.key],
        ) !=
        1) {
      throw StateError('Card missing');
    }
  }

  Future<void> reflectOnCard(Day day, String reflection) async {
    if (reflection.length > 10000) throw ArgumentError('Reflection too long');
    if (await db.update(
          'cards',
          {'reflection': reflection},
          where: 'day=?',
          whereArgs: [day.key],
        ) !=
        1) {
      throw StateError('Card missing');
    }
  }
}
