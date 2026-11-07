import 'models.dart';

/// Local starting points. Picking one never persists anything by itself.
class HabitTemplate {
  const HabitTemplate(
    this.id,
    this.icon,
    this.zh,
    this.en,
    this.keywords, {
    this.target = 1000,
    this.unitZh = '',
    this.unitEn = '',
    this.context = HabitContext.anytime,
  });
  final String id, zh, en, unitZh, unitEn;
  final int icon, target;
  final List<String> keywords;
  final HabitContext context;
  HabitKind get kind => unitEn.isEmpty ? HabitKind.check : HabitKind.quantity;
  String title(bool chinese) => chinese ? zh : en;
  String unit(bool chinese) => chinese ? unitZh : unitEn;
}

const habitTemplates = [
  HabitTemplate(
    'water',
    1,
    '喝水',
    'Drink water',
    ['喝水', '饮水', 'water', 'hydrate'],
    target: 1500000,
    unitZh: '毫升',
    unitEn: 'ml',
  ),
  HabitTemplate(
    'reading',
    2,
    '阅读',
    'Read',
    ['阅读', '读书', '看书', 'reading', 'read', 'book'],
    target: 10000,
    unitZh: '页',
    unitEn: 'pages',
  ),
  HabitTemplate(
    'walking',
    3,
    '散步',
    'Walk',
    ['散步', '步行', '走路', 'walk', 'steps'],
    target: 6000000,
    unitZh: '步',
    unitEn: 'steps',
  ),
  HabitTemplate(
    'stretch',
    7,
    '拉伸',
    'Stretch',
    ['拉伸', '瑜伽', 'stretch', 'yoga'],
    target: 10000,
    unitZh: '分钟',
    unitEn: 'min',
  ),
  HabitTemplate('sleep', 21, '按时睡觉', 'Sleep on time', [
    '睡觉',
    '早睡',
    'sleep',
    'bedtime',
  ], context: HabitContext.evening),
  HabitTemplate('journal', 14, '写日记', 'Keep a journal', [
    '日记',
    '写作',
    '手记',
    'journal',
    'write',
    'writing',
  ], context: HabitContext.evening),
  HabitTemplate('breakfast', 10, '吃早餐', 'Eat breakfast', [
    '早餐',
    '吃饭',
    'meal',
    'breakfast',
  ]),
  HabitTemplate('tidy', 17, '整理房间', 'Tidy up', [
    '整理',
    '打扫',
    '清洁',
    'tidy',
    'clean',
  ]),
  HabitTemplate(
    'running',
    8,
    '跑步',
    'Run',
    ['跑步', 'run', 'jog'],
    target: 3000,
    unitZh: '公里',
    unitEn: 'km',
  ),
  HabitTemplate(
    'cycling',
    9,
    '骑行',
    'Cycle',
    ['骑行', '骑车', 'cycle', 'cycling', 'bike'],
    target: 5000,
    unitZh: '公里',
    unitEn: 'km',
  ),
  HabitTemplate(
    'language',
    15,
    '学外语',
    'Learn a language',
    ['外语', '英语', '单词', 'language', 'english', 'vocabulary'],
    target: 10000,
    unitZh: '词',
    unitEn: 'words',
  ),
  HabitTemplate('plant', 11, '照顾植物', 'Care for plants', [
    '植物',
    '浇花',
    '浇水',
    'plant',
    'plants',
    'garden',
  ]),
  HabitTemplate(
    'music',
    12,
    '练习乐器',
    'Practice music',
    ['乐器', '吉他', '钢琴', 'music', 'piano', 'guitar'],
    target: 15000,
    unitZh: '分钟',
    unitEn: 'min',
  ),
  HabitTemplate('art', 13, '画画', 'Draw', [
    '画画',
    '绘画',
    '画图',
    'draw',
    'paint',
    'art',
  ]),
  HabitTemplate('strength', 6, '力量练习', 'Strength training', [
    '力量',
    '健身',
    '哑铃',
    'strength',
    'workout',
    'gym',
  ]),
  HabitTemplate('unplug', 22, '放下手机', 'Put the phone away', [
    '手机',
    '屏幕',
    'phone',
    'screen',
    'unplug',
  ], context: HabitContext.evening),
];

/// Whole English words avoid accidental matches such as "art" in "start".
int? suggestedHabitIcon(String title) {
  final value = title.trim().toLowerCase();
  if (value.isEmpty) return null;
  final ordered = [
    ...habitTemplates.where((t) => t.id == 'plant'),
    ...habitTemplates.where((t) => t.id != 'plant'),
  ];
  for (final t in ordered) {
    for (final word in t.keywords) {
      final match = RegExp(r'^[a-z ]+$').hasMatch(word)
          ? RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(value)
          : value.contains(word);
      if (match) return t.icon;
    }
  }
  const extras = {
    0: ['早起', '起床', 'wake', 'morning'],
    4: ['健康', '心情', 'health', 'heart'],
    5: ['晚安', 'night', 'moon'],
    16: ['存钱', '储蓄', 'save money', 'savings'],
    18: ['宠物', '喂猫', '遛狗', 'pet', 'dog', 'cat'],
    19: ['咖啡', 'coffee'],
    20: ['吃药', '用药', 'medicine', 'medication'],
    23: ['关心', '感恩', '家人', 'care', 'gratitude', 'family'],
  };
  for (final e in extras.entries) {
    for (final w in e.value) {
      if (RegExp(r'^[a-z ]+$').hasMatch(w)
          ? RegExp('\\b${RegExp.escape(w)}\\b').hasMatch(value)
          : value.contains(w)) {
        return e.key;
      }
    }
  }
  return null;
}

/// Explicit total suggestions in thousandths, using the selected day's unit.
/// These values only fill the editor; they never accumulate or write records.
List<int> quantitySuggestions(int target, String unit) {
  final values = switch (unit.trim().toLowerCase()) {
    'ml' || '毫升' => [250000, 500000, 1000000],
    '页' || 'page' || 'pages' => [1000, 5000, 10000],
    '步' || 'step' || 'steps' => [1000000, 3000000, 6000000],
    '分钟' || 'min' || 'minute' || 'minutes' => [5000, 10000, 15000],
    '公里' || '千米' || 'km' => [1000, 3000, 5000],
    '词' || 'word' || 'words' => [5000, 10000, 20000],
    _ => [target ~/ 4, target ~/ 2, target * 3 ~/ 4],
  };
  return {...values.where((v) => v > 0 && v < target), target}.toList()..sort();
}
