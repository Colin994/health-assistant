import 'package:flutter/foundation.dart';

/// 看星星参数(《慢植物小游戏设计方案》§6.2.1,eyes-free 仰头玩法)。
///
/// 设计原则:仰头时屏幕出视野——视觉只做余光提示,主反馈走音频;
/// 判定用「对准 + 持续」而非角度精度;回中星用得分引导头回正,
/// 使单次后伸 ≤15 秒由关卡结构保证,不靠打断(§6.2 安全)。
@immutable
class StarGazingConfig {
  const StarGazingConfig({
    this.sessionDuration = const Duration(seconds: 40),
    this.targetScore = 100,
    this.alignToleranceDeg = 5,
    this.stars = const [
      StarTarget(pitch: 8, hold: Duration(seconds: 3), score: 25, recentring: false),
      StarTarget(pitch: 2, hold: Duration(seconds: 1), score: 5, recentring: true),
      StarTarget(pitch: 14, hold: Duration(seconds: 3), score: 25, recentring: false),
      StarTarget(pitch: 2, hold: Duration(seconds: 1), score: 5, recentring: true),
      StarTarget(pitch: 20, hold: Duration(seconds: 3), score: 25, recentring: false),
      StarTarget(pitch: 2, hold: Duration(seconds: 1), score: 5, recentring: true),
      StarTarget(pitch: 26, hold: Duration(seconds: 3), score: 25, recentring: false),
      StarTarget(pitch: 2, hold: Duration(seconds: 1), score: 5, recentring: true),
      StarTarget(pitch: 30, hold: Duration(seconds: 3), score: 25, recentring: false),
    ],
    this.stardustBase = 12,
    this.stardustPerScore = 0.09,
    this.stardustCap = 25,
    this.tickInterval = const Duration(milliseconds: 100),
  });

  /// 单局硬限时。
  final Duration sessionDuration;

  /// 目标分(达成可提前完成)。
  final int targetScore;

  /// 对准容差(±度)。
  final double alignToleranceDeg;

  /// 星星序列(star 与回中星交替)。
  final List<StarTarget> stars;

  /// 星屑换算:基础 + 分数 × 系数,封顶(§5.2:15~25/局按表现)。
  final int stardustBase;
  final double stardustPerScore;
  final int stardustCap;

  final Duration tickInterval;

  static const StarGazingConfig standard = StarGazingConfig();

  /// 分数 → 星屑(§5.2)。
  int stardustFor(int score) {
    final raw = stardustBase + score * stardustPerScore;
    return raw.clamp(0, stardustCap).round();
  }
}

/// 一颗星(或回中星)的目标。
@immutable
class StarTarget {
  const StarTarget({
    required this.pitch,
    required this.hold,
    required this.score,
    required this.recentring,
  });

  /// 目标仰角(度,正=仰头)。
  final double pitch;

  /// 对准后需保持的时长。
  final Duration hold;

  /// 收集得分。
  final int score;

  /// 是否回中星(低仰角,用于让颈回到中立位)。
  final bool recentring;
}

/// 星星会话阶段。
enum StarGazingPhase { playing, finished }

/// 局内快照(渲染 + 音频消费)。
@immutable
class StarGazingSnapshot {
  const StarGazingSnapshot({
    required this.phase,
    required this.elapsed,
    required this.score,
    required this.currentIndex,
    required this.targetPitch,
    required this.targetIsRecentring,
    required this.holdProgress,
    required this.aligned,
    required this.collectedCount,
    required this.canFinishEarly,
  });

  final StarGazingPhase phase;
  final Duration elapsed;
  final int score;

  /// 当前目标序号(collect → 下一颗)。
  final int currentIndex;

  /// 当前目标仰角(度;已收集完则为最后一颗)。
  final double targetPitch;

  /// 当前目标是否回中星。
  final bool targetIsRecentring;

  /// 当前目标充能进度 0~1(仅对准时增长;中断保留)。
  final double holdProgress;

  /// 当前是否对准(渲染边框发光 + 音频渐强的判据)。
  final bool aligned;

  /// 已收集数量(含回中星)。
  final int collectedCount;

  final bool canFinishEarly;
}

/// 看星星会话(纯逻辑,外部时钟驱动,可回放)。
///
/// 输入:每拍 pitch 相对角(度,零点=平视地平线)。
/// 对准当前目标(±容差)即累计充能,充满得分并点亮下一颗;
/// 中断进度保留(无惩罚)。全部收集或时间到 → finished。
class StarGazingSession {
  StarGazingSession({StarGazingConfig? config})
      : config = config ?? StarGazingConfig.standard;

  final StarGazingConfig config;

  Duration _elapsed = Duration.zero;
  int _score = 0;
  int _index = 0;
  Duration _hold = Duration.zero;
  bool _aligned = false;
  int _collected = 0;
  StarGazingPhase _phase = StarGazingPhase.playing;

  StarTarget get _target => config.stars[_index.clamp(0, config.stars.length - 1)];

  bool get _allCollected => _index >= config.stars.length;

  StarGazingSnapshot get snapshot => StarGazingSnapshot(
        phase: _phase,
        elapsed: _elapsed,
        score: _score,
        currentIndex: _index,
        targetPitch: _target.pitch,
        targetIsRecentring: _target.recentring,
        holdProgress: _target.hold.inMilliseconds == 0
            ? 0
            : (_hold.inMilliseconds / _target.hold.inMilliseconds)
                .clamp(0.0, 1.0),
        aligned: _aligned && !_allCollected,
        collectedCount: _collected,
        canFinishEarly: _score >= config.targetScore,
      );

  /// 提前完成(需达目标分;全部收集后也允许)。
  bool finishEarly() {
    if (_score < config.targetScore) {
      return false;
    }
    _phase = StarGazingPhase.finished;
    return true;
  }

  /// 推进一拍。[headPitch] 为头部相对仰角(度)。
  StarGazingSnapshot advance({
    required Duration dt,
    required double headPitch,
  }) {
    if (_phase == StarGazingPhase.finished) {
      return snapshot;
    }
    _elapsed += dt;
    if (_elapsed >= config.sessionDuration) {
      _phase = StarGazingPhase.finished;
      return snapshot;
    }
    if (_allCollected) {
      return snapshot;
    }

    final distance = (headPitch - _target.pitch).abs();
    _aligned = distance <= config.alignToleranceDeg;
    if (_aligned) {
      _hold += dt;
      if (_hold >= _target.hold) {
        _score += _target.score;
        _collected++;
        _index++;
        _hold = Duration.zero;
        _aligned = false;
      }
    }
    // 不对准:进度保留(§6.2 无惩罚),仅不再增长。

    return snapshot;
  }

  // ---- 只读 ----

  Duration get elapsed => _elapsed;
  int get score => _score;
  int get collectedCount => _collected;
  StarGazingPhase get phase => _phase;
  int get currentIndex => _index;
  bool get allCollected => _allCollected;
}
