import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_economy_models.dart';

/// 游戏持久化(W2 决策延续:Prefs JSON;表语义与设计方案 §5 v0.5 一致)。
///
/// 语义要点:
/// - 额度按局计,开局时扣(退出/失败不返还)
/// - 跨日自动重置(纯读取视角,磁盘随下次写操作更新)
/// - 阳光上限 999;基础种子免费无限(无库存概念)
/// - 地块:种/投/收;收获计入押花册;任意盛开解锁看星星
@LazySingleton()
class GameEconomyStore {
  GameEconomyStore();

  static const String _prefsKey = 'l4_game_economy';

  GameEconomyState _state = const GameEconomyState();
  bool _loaded = false;

  /// 当前状态(未加载时为空态;先 [load])。
  GameEconomyState get state => _state;

  /// 从磁盘载入(幂等;兼容旧版无地块/装饰字段的 JSON)。
  Future<GameEconomyState> load() async {
    if (_loaded) {
      return _state;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final json = Map<String, Object?>.from(jsonDecode(raw) as Map);
        final plots = List<PlotState?>.filled(
          GameEconomyState.plotCount,
          null,
          growable: false,
        );
        final rawPlots = json['plots'];
        if (rawPlots is List) {
          for (var i = 0; i < rawPlots.length && i < plots.length; i++) {
            final p = rawPlots[i];
            if (p is Map) {
              plots[i] = PlotState(
                species: (p['species'] as String?) ?? '',
                invested: (p['invested'] as int?) ?? 0,
              );
            }
          }
        }
        final decorations = <String>[];
        final rawDecorations = json['decorations'];
        if (rawDecorations is List) {
          decorations.addAll(
            rawDecorations.whereType<String>(),
          );
        }
        _state = GameEconomyState(
          sunshineTotal: (json['sunshineTotal'] as int?) ?? 0,
          stardustTotal: (json['stardustTotal'] as int?) ?? 0,
          quotaDay: (json['quotaDay'] as String?) ?? '',
          quotaUsed: (json['quotaUsed'] as int?) ?? 0,
          plots: plots,
          decorations: decorations,
          harvestedCount: (json['harvestedCount'] as int?) ?? 0,
          harvestCounts: _intMap(json['harvestCounts']),
          unlockedAdvancedSeeds: _stringList(json['unlockedAdvancedSeeds']),
        );
      } catch (_) {
        // 损坏数据:回到空态(经济数值可重建,不致崩溃)。
        _state = const GameEconomyState();
      }
    }
    _loaded = true;
    return _state;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(<String, Object?>{
        'sunshineTotal': _state.sunshineTotal,
        'stardustTotal': _state.stardustTotal,
        'quotaDay': _state.quotaDay,
        'quotaUsed': _state.quotaUsed,
        'plots': _state.plots
            .map((p) => p == null
                ? null
                : {'species': p.species, 'invested': p.invested})
            .toList(),
        'decorations': _state.decorations,
        'harvestedCount': _state.harvestedCount,
        'harvestCounts': _state.harvestCounts,
        'unlockedAdvancedSeeds': _state.unlockedAdvancedSeeds,
      }),
    );
  }

  static Map<String, int> _intMap(Object? raw) {
    if (raw is Map) {
      final out = <String, int>{};
      raw.forEach((k, v) {
        if (k is String && v is int) {
          out[k] = v;
        }
      });
      return out;
    }
    return const {};
  }

  static List<String> _stringList(Object? raw) {
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    return const [];
  }

  static String _dayKey(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  /// 结算入账阳光(上限 999 截断,§5.2)。
  Future<GameEconomyState> addSunshine(int amount) async {
    await _ensureLoaded();
    final next = (_state.sunshineTotal + amount)
        .clamp(0, GameEconomyState.sunshineCap);
    _state = _state.copyWith(sunshineTotal: next);
    await _save();
    return _state;
  }

  /// 写操作前置:未加载先加载(避免基于空态覆盖磁盘导致毁档)。
  Future<void> _ensureLoaded() async {
    if (!_loaded) {
      await load();
    }
  }

  /// 开局扣额度:跨日自动重置;当日已满返回 false(开局被拒)。
  Future<bool> tryUseDailyQuota(DateTime now) async {
    await _ensureLoaded();
    final today = _dayKey(now);
    if (_state.quotaDay != today) {
      _state = _state.copyWith(quotaDay: today, quotaUsed: 0);
    }
    if (_state.quotaUsed >= GameEconomyState.dailyQuotaLimit) {
      await _save();
      return false;
    }
    _state = _state.copyWith(quotaUsed: _state.quotaUsed + 1);
    await _save();
    return true;
  }

  /// 今日剩余局数(跨日视角;纯读取无副作用)。
  int quotaRemaining(DateTime now) {
    final today = _dayKey(now);
    final used = _state.quotaDay == today ? _state.quotaUsed : 0;
    return GameEconomyState.dailyQuotaLimit - used;
  }

  /// 星屑入账(看星星产出;无上限,§5.2)。
  Future<GameEconomyState> addStardust(int amount) async {
    await _ensureLoaded();
    _state = _state.copyWith(
      stardustTotal: _state.stardustTotal + amount.clamp(0, 999),
    );
    await _save();
    return _state;
  }

  /// 星屑兑换高级种子:满 100 星屑 → 自动解锁目录中下一颗高级种。
  /// 返回解锁的物种 id(null = 星屑不足或已全部解锁)。
  Future<String?> tryExchangeAdvancedSeed() async {
    await _ensureLoaded();
    final next = _state.nextAdvancedSeed;
    if (next == null ||
        _state.stardustTotal <
            GameEconomyState.stardustPerAdvancedSeed) {
      return null;
    }
    _state = _state.copyWith(
      stardustTotal:
          _state.stardustTotal - GameEconomyState.stardustPerAdvancedSeed,
      unlockedAdvancedSeeds: [..._state.unlockedAdvancedSeeds, next],
    );
    await _save();
    return next;
  }

  // ---------- 地块(§4.4 花园 MVP) ----------

  /// 空地种下种子(基础种免费;高级种需已用星屑兑换,§5.1)。
  Future<bool> plantSeed(int plotIndex, String species) async {
    await _ensureLoaded();
    if (plotIndex < 0 || plotIndex >= _state.plots.length) {
      return false;
    }
    if (_state.plots[plotIndex] != null) {
      return false;
    }
    if (!_state.plantableSpecies.contains(species)) {
      return false;
    }
    final plots = List<PlotState?>.from(_state.plots);
    plots[plotIndex] = PlotState(species: species, invested: 0);
    _state = _state.copyWith(plots: plots);
    await _save();
    return true;
  }

  /// 向地块投入阳光:实投 = min(amount, 阳光余额, 距全程线余量)。
  /// 返回实际投入值(0 = 余额不足或已到全程线)。
  Future<int> investSunshine(int plotIndex, int amount) async {
    await _ensureLoaded();
    final plot = _state.plots.elementAtOrNull(plotIndex);
    if (plot == null || amount <= 0) {
      return 0;
    }
    final room = PlotState.fullCourse - plot.invested;
    if (room <= 0) {
      return 0;
    }
    final actual = amount
        .clamp(0, room)
        .clamp(0, _state.sunshineTotal);
    if (actual <= 0) {
      return 0;
    }
    final plots = List<PlotState?>.from(_state.plots);
    plots[plotIndex] = plot.copyWith(invested: plot.invested + actual);
    _state = _state.copyWith(
      sunshineTotal: _state.sunshineTotal - actual,
      plots: plots,
    );
    await _save();
    return actual;
  }

  /// 收获(需 invested ≥ 全程线):押花册 +1、地块清空,返回物种 id。
  Future<String?> harvest(int plotIndex) async {
    await _ensureLoaded();
    final plot = _state.plots.elementAtOrNull(plotIndex);
    if (plot == null || !plot.harvestable) {
      return null;
    }
    final plots = List<PlotState?>.from(_state.plots);
    plots[plotIndex] = null;
    final counts = Map<String, int>.from(_state.harvestCounts);
    counts[plot.species] = (counts[plot.species] ?? 0) + 1;
    _state = _state.copyWith(
      plots: plots,
      harvestedCount: _state.harvestedCount + 1,
      harvestCounts: counts,
    );
    await _save();
    return plot.species;
  }

  /// 购买装饰(阳光定价;买了即显示)。
  Future<bool> buyDecoration(String id) async {
    await _ensureLoaded();
    final def = decorationCatalog.where((d) => d.id == id).firstOrNull;
    if (def == null || _state.decorations.contains(id)) {
      return false;
    }
    if (_state.sunshineTotal < def.priceSunshine) {
      return false;
    }
    _state = _state.copyWith(
      sunshineTotal: _state.sunshineTotal - def.priceSunshine,
      decorations: [..._state.decorations, id],
    );
    await _save();
    return true;
  }

  /// 看星星资格(任意植物盛开;派生值不落盘)。
  bool get isStarGazeUnlocked => _state.starGazeUnlocked;
}

/// firstOrNull 扩展(避免仅为一个方法引入 collection 包)。
extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
