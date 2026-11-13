import 'package:flutter/foundation.dart';

/// 种子目录(《慢植物小游戏设计方案》§4.1/§5.1 v0.5:基础免费无限领)。
@immutable
class SeedDef {
  const SeedDef({
    required this.id,
    required this.name,
    required this.basic,
  });

  final String id;

  /// 展示名(与植物立绘物种一致)。
  final String name;

  /// 是否基础种(商店免费领;false = 高级种,星屑兑换)。
  final bool basic;
}

/// 全量种子目录(顺序即选择列表序)。
const List<SeedDef> seedCatalog = [
  SeedDef(id: 'sunflower', name: '向日葵', basic: true),
  SeedDef(id: 'hydrocotyle', name: '铜钱草', basic: true),
  SeedDef(id: 'cyperus', name: '风车草', basic: true),
  SeedDef(id: 'lavender', name: '薰衣草', basic: true),
  SeedDef(id: 'rose', name: '玫瑰', basic: false),
];

/// 装饰目录(v0.5:阳光直购、买了即显示,不做槽位解锁)。
@immutable
class DecorationDef {
  const DecorationDef({
    required this.id,
    required this.name,
    required this.priceSunshine,
  });

  final String id;
  final String name;

  /// 阳光定价(30~80)。
  final int priceSunshine;
}

/// 全量装饰目录(与 design/game_art/decor_512 八件一一对应)。
const List<DecorationDef> decorationCatalog = [
  DecorationDef(id: 'path', name: '石板小径', priceSunshine: 30),
  DecorationDef(id: 'hanging_pot', name: '吊盆', priceSunshine: 35),
  DecorationDef(id: 'fence', name: '木围栏', priceSunshine: 40),
  DecorationDef(id: 'bench', name: '长椅', priceSunshine: 45),
  DecorationDef(id: 'lantern', name: '庭院灯', priceSunshine: 50),
  DecorationDef(id: 'wheelbarrow', name: '手推车', priceSunshine: 55),
  DecorationDef(id: 'gnome', name: '小矮人', priceSunshine: 60),
  DecorationDef(id: 'pavilion', name: '凉亭', priceSunshine: 80),
];

/// 单块地块的植物状态(§4.2 成长阶段)。
@immutable
class PlotState {
  const PlotState({required this.species, required this.invested});

  /// 物种 id(seedCatalog 之一)。
  final String species;

  /// 累计投入阳光。
  final int invested;

  /// 每阶段所需阳光(普通植物全程 450 ÷ 6 阶段,§5.2)。
  static const int sunshinePerStage = 75;

  /// 全程线:达到即可收获。
  static const int fullCourse = 450;

  /// 当前成长阶段 0~5(= 发芽/幼苗/成长/花苞/盛开/待收)。
  int get stage => (invested ~/ sunshinePerStage).clamp(0, 5);

  /// 盛开(stage≥4)= 看星星解锁线(§6.2 Pro 资格)。
  bool get bloomed => stage >= 4;

  /// 待收(invested ≥ 450)。
  bool get harvestable => invested >= fullCourse;

  /// 下一阶段进度 0~1(已盛开到顶则为待收进度)。
  double get progressToNext {
    if (harvestable) {
      return 1;
    }
    return (invested % sunshinePerStage) / sunshinePerStage;
  }

  PlotState copyWith({int? invested}) =>
      PlotState(species: species, invested: invested ?? this.invested);
}

/// 游戏经济状态(不可变;持久化快照,§5 经济系统 v0.5)。
@immutable
class GameEconomyState {
  const GameEconomyState({
    this.sunshineTotal = 0,
    this.stardustTotal = 0,
    this.quotaDay = '',
    this.quotaUsed = 0,
    this.plots = const [null, null, null, null],
    this.decorations = const [],
    this.harvestedCount = 0,
    this.harvestCounts = const {},
    this.unlockedAdvancedSeeds = const [],
  });

  /// 阳光累计(上限 999,§5.2)。
  final int sunshineTotal;

  /// 星屑累计(看星星产出;§5.2)。
  final int stardustTotal;

  /// 额度所属日('yyyy-MM-dd' 本地时区)。
  final String quotaDay;

  /// 当日已用练习局数。
  final int quotaUsed;

  /// 四块地块(null = 空地;§4.4 花园 MVP)。
  final List<PlotState?> plots;

  /// 已购装饰 id 列表。
  final List<String> decorations;

  /// 押花册计数(收获次数累计)。
  final int harvestedCount;

  /// 按物种的收获次数(押花册页面用;兼容旧数据为空)。
  final Map<String, int> harvestCounts;

  /// 已用星屑兑换的高级种子物种 id(§5.1)。
  final List<String> unlockedAdvancedSeeds;

  static const int sunshineCap = 999;
  static const int dailyQuotaLimit = 3;
  static const int plotCount = 4;

  /// 星屑兑换阈值(§5.2:100 星屑 = 1 颗高级种子)。
  static const int stardustPerAdvancedSeed = 100;

  /// 可种物种 = 基础种 ∪ 已兑换高级种。
  Set<String> get plantableSpecies => {
        ...seedCatalog.where((s) => s.basic).map((s) => s.id),
        ...unlockedAdvancedSeeds,
      };

  /// 下一颗待解锁的高级种子(null = 全部已解锁)。
  String? get nextAdvancedSeed => seedCatalog
      .where((s) => !s.basic && !unlockedAdvancedSeeds.contains(s.id))
      .map((s) => s.id)
      .firstOrNull;

  /// 看星星资格:任意植物盛开,或收获过(首株开花后永久有效,§6.2)。
  bool get starGazeUnlocked =>
      plots.any((p) => p != null && p.bloomed) || harvestedCount > 0;

  GameEconomyState copyWith({
    int? sunshineTotal,
    int? stardustTotal,
    String? quotaDay,
    int? quotaUsed,
    List<PlotState?>? plots,
    List<String>? decorations,
    int? harvestedCount,
    Map<String, int>? harvestCounts,
    List<String>? unlockedAdvancedSeeds,
  }) {
    return GameEconomyState(
      sunshineTotal: sunshineTotal ?? this.sunshineTotal,
      stardustTotal: stardustTotal ?? this.stardustTotal,
      quotaDay: quotaDay ?? this.quotaDay,
      quotaUsed: quotaUsed ?? this.quotaUsed,
      plots: plots ?? this.plots,
      decorations: decorations ?? this.decorations,
      harvestedCount: harvestedCount ?? this.harvestedCount,
      harvestCounts: harvestCounts ?? this.harvestCounts,
      unlockedAdvancedSeeds:
          unlockedAdvancedSeeds ?? this.unlockedAdvancedSeeds,
    );
  }
}

/// firstOrNull(避免仅为该方法引入 collection 包)。
extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
