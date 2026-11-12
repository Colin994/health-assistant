import 'package:flutter/services.dart';

/// 游戏反馈(触感 + 音效)抽象。
///
/// 当前为零资源实现:触感走 HapticFeedback,音效走系统音。
/// 接入正式音效时替换 [GameFeel.standard] 即可(UI/Session 不改)。
abstract interface class GameFeel {
  /// 当前实现(可被测试/正式音效替换)。
  static GameFeel standard = const HapticGameFeel();

  /// 接住普通掉落物。
  void onCatch(int combo);

  /// 金阳光出现(提醒用户注意)。
  void onGoldenAppear();

  /// 看星星:对准中(节拍脉冲,eyes-free 主通道——用户仰头时看不到屏幕)。
  void onStarAligned();

  /// 看星星:收集到一颗星。
  void onStarCollected();

  /// 接住金阳光。
  void onGoldenCatch();

  /// 漏接(不扣分,仅轻提示;静音实现可为空)。
  void onMiss();

  /// 连击中断。
  void onComboBroken();

  /// 结算。
  void onFinish();

  /// 点击按钮。
  void onTap();

  /// 开始一局(倒计时结束/校准完成)。
  void onStart();
}

/// 默认实现:触感为主 + 系统音点缀(零音频资源)。
///
/// 音效资源就绪后:新增 `AudioGameFeel`(audioplayers)实现本接口,
/// 在 VM 侧换掉 [GameFeel.standard] 即可——调用点不变。
class HapticGameFeel implements GameFeel {
  const HapticGameFeel();

  /// 触感/系统音在无平台(单元测试、桌面)时静默失败。
  static void _safe(void Function() action) {
    try {
      action();
    } catch (_) {
      // 无 binding / 无平台实现:忽略。
    }
  }

  @override
  void onCatch(int combo) {
    // 连击越高,触感越"实"。
    _safe(() {
      if (combo >= 5) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      SystemSound.play(SystemSoundType.click);
    });
  }

  @override
  void onGoldenAppear() {
    _safe(() {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    });
  }

  @override
  void onStarAligned() {
    // 对准脉冲:轻震。仰头时视线离开屏幕,触感是唯一可感知的「还在对准」信号。
    _safe(HapticFeedback.selectionClick);
  }

  @override
  void onStarCollected() {
    _safe(() {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.alert);
    });
  }

  @override
  void onGoldenCatch() {
    _safe(() {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    });
  }

  @override
  void onMiss() {
    // 漏接不惩罚:不震不响,避免负面反馈(§2 无惩罚)。
  }

  @override
  void onComboBroken() {
    _safe(HapticFeedback.selectionClick);
  }

  @override
  void onFinish() {
    _safe(() {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.alert);
    });
  }

  @override
  void onTap() {
    _safe(HapticFeedback.selectionClick);
  }

  @override
  void onStart() {
    _safe(HapticFeedback.mediumImpact);
  }
}
