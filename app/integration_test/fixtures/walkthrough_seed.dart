import 'dart:convert';

/// UI 走查 v1：内存 Prefs，不覆盖设备原有存档。不代表磁盘持久化验收。
Map<String, Object> walkthroughSeed() => {
  'onboarding_done': true,
  'health_tags_v1': <String>[],
  'l4_game_economy': jsonEncode({
    'sunshineTotal': 120,
    'stardustTotal': 110,
    'harvestedCount': 2,
    'harvestCounts': {'sunflower': 2},
    'plots': [
      {'species': 'sunflower', 'invested': 150},
      null,
      null,
      null,
    ],
  }),
};
