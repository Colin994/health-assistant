import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game_state.dart';
import '../game_intent.dart';
import '../garden_scene.dart';
import 'garden_panels.dart';
import 'garden_scene_layout.dart';
import 'garden_ui_theme.dart';

class GardenView extends StatelessWidget {
  const GardenView({super.key, required this.state, required this.onIntent});
  final GameState state;
  final ValueChanged<GameIntent> onIntent;
  Future<void> _panel(
    BuildContext context,
    GardenPanel panel, {
    int? plotIndex,
  }) async {
    final next = await showGardenPanel(context, panel, plotIndex: plotIndex);
    if (!context.mounted) return;
    if (next == GardenPanelFollowUp.practice) {
      await startGardenPractice(
        context,
        state,
        const StartCatchDropPressed(),
        onIntent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state.phase != GamePhase.idle) {
      return _GardenPreparation(state: state, onIntent: onIntent);
    }
    void onHerbarium() => _panel(context, GardenPanel.herbarium);
    void onShop() => _panel(context, GardenPanel.shop);
    void onStart(GameIntent intent) =>
        startGardenPractice(context, state, intent, onIntent);
    Widget scene() => GardenSceneView(
      plots: state.plots,
      decorations: state.decorations,
      time: state.gardenTime,
      feedback: state.feedback,
      immersive: true,
      onPlot: (i) => _panel(
        context,
        state.plots[i] == null ? GardenPanel.seed : GardenPanel.plant,
        plotIndex: i,
      ),
    );
    return LayoutBuilder(
      builder: (context, c) {
        final expandedText = MediaQuery.textScalerOf(context).scale(14) > 19;
        // The world fills the screen; the interface is a handful of floating
        // objects, not three vertically stacked application sections.
        if (c.maxHeight >= 600 && !expandedText) {
          return _GardenImmersive(
            stage: GardenStage(Size(c.maxWidth, c.maxHeight)),
            state: state,
            scene: scene(),
            onStart: onStart,
            onShop: onShop,
            onHerbarium: onHerbarium,
          );
        }
        // Keep one world transform even when the controls need to scroll.
        // A second, focus-cropped scene creates a visible rectangular seam.
        return Stack(
          fit: StackFit.expand,
          children: [
            scene(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, safe) => SingleChildScrollView(
                  hitTestBehavior: HitTestBehavior.translucent,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: safe.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: _GardenStats(state: state),
                        ),
                        const SizedBox(height: 280),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _GardenActions(
                            state: state,
                            onStart: onStart,
                            onShop: onShop,
                            onHerbarium: onHerbarium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The scene owns the window and the controls float over it.
///
/// Phones and portrait tablets stack the controls top and bottom. A wide
/// window narrows the world and, once both margins fit a rail, moves the
/// actions beside the scene so they stop covering the near beds.
class _GardenImmersive extends StatelessWidget {
  const _GardenImmersive({
    required this.stage,
    required this.state,
    required this.scene,
    required this.onStart,
    required this.onShop,
    required this.onHerbarium,
  });

  final GardenStage stage;
  final GameState state;
  final Widget scene;
  final ValueChanged<GameIntent> onStart;
  final VoidCallback onShop;
  final VoidCallback onHerbarium;

  /// Bottom actions stay in a readable cluster instead of hugging the edges.
  static const double _actionSpan = 640;

  /// Actions block inside a rail: [GardenStage.railWidth] less its margins.
  static const double _railContent = GardenStage.railWidth - 32;

  @override
  Widget build(BuildContext context) {
    final rails = stage.hasRails;
    return Stack(
      fit: StackFit.expand,
      children: [
        _GardenWorld(stage: stage, time: state.gardenTime, child: scene),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, safe) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _GardenStats(state: state, showStatus: !rails),
                ),
                if (rails && state.statusText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Align(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: math.min(stage.worldWidth, safe.maxWidth),
                        ),
                        child: _GardenStatus(state.statusText),
                      ),
                    ),
                  ),
                const Spacer(),
                Align(
                  alignment: rails
                      ? AlignmentDirectional.bottomEnd
                      : Alignment.bottomCenter,
                  child: Padding(
                    padding: rails
                        ? const EdgeInsetsDirectional.only(end: 16, bottom: 16)
                        : const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: rails ? _railContent : _actionSpan,
                      ),
                      child: _GardenActions(
                        state: state,
                        onStart: onStart,
                        onShop: onShop,
                        onHerbarium: onHerbarium,
                        stacked: rails,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One scene, framed by [GardenStage]: edge to edge on phones, narrowed with
/// continuous margins on wide windows.
class _GardenWorld extends StatelessWidget {
  const _GardenWorld({
    required this.stage,
    required this.time,
    required this.child,
  });

  final GardenStage stage;
  final GardenTimeOfDay time;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // The same transform the scene uses for its background, plants and
        // hit targets, so the margins line up with it band by band.
        final layout = GardenSceneLayout(
          Size(stage.worldWidth, c.maxHeight),
          immersive: true,
        );
        return GardenFramedScene(
          width: stage.worldWidth,
          bands: kGardenEdgeBands[time]!,
          imageSize: GardenSceneLayout.imageSize,
          imageTop: layout.translation.dy,
          imageHeight: GardenSceneLayout.imageSize.height * layout.scale,
          mirror: kGardenIsoAssets[time],
          child: child,
        );
      },
    );
  }
}

/// A short live message on parchment, such as a failed action or used quota.
class _GardenStatus extends StatelessWidget {
  const _GardenStatus(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => GardenPaper(
    child: Semantics(liveRegion: true, child: Text(text)),
  );
}

class _GardenStats extends StatelessWidget {
  const _GardenStats({required this.state, this.showStatus = true});
  final GameState state;
  final bool showStatus;
  static const _resourceTop = 60.0;
  static const _resourceHeight = 44.0;
  static const _resourceGap = 8.0;

  @override
  Widget build(BuildContext context) {
    final expandedText = MediaQuery.textScalerOf(context).scale(14) > 19;
    final showStardust = state.starGazeUnlocked || state.stardustTotal > 0;
    final title = _GardenTitleSign(hanging: !expandedText);
    final resources = _GardenResources(
      state: state,
      showStardust: showStardust,
    );
    final status = !showStatus || state.statusText.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _GardenStatus(state.statusText),
          );
    if (expandedText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: AlignmentDirectional.centerStart, child: title),
          const SizedBox(height: 8),
          Align(alignment: AlignmentDirectional.centerEnd, child: resources),
          ?status,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height:
              _resourceTop +
              _resourceHeight +
              (showStardust ? _resourceGap + _resourceHeight : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PositionedDirectional(top: 0, start: 0, child: title),
              PositionedDirectional(
                top: _resourceTop,
                end: 0,
                child: resources,
              ),
            ],
          ),
        ),
        ?status,
      ],
    );
  }
}

class _GardenTitleSign extends StatelessWidget {
  const _GardenTitleSign({this.hanging = true});
  final bool hanging;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    key: const ValueKey('garden-title-rotation'),
    angle: -3 * math.pi / 180,
    child: GardenWood(
      hanging: hanging,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: hanging ? 12 : 6,
        ),
        child: const Text(
          '慢植物',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: GardenUiTheme.paper,
          ),
        ),
      ),
    ),
  );
}

class _GardenResources extends StatelessWidget {
  const _GardenResources({required this.state, required this.showStardust});

  final GameState state;
  final bool showStardust;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('garden-resources'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      _GardenResource(
        label: '阳光',
        value: state.todaySunshineTotal,
        sunlight: true,
      ),
      if (showStardust) ...[
        const SizedBox(height: 8),
        _GardenResource(
          label: '星屑',
          value: state.stardustTotal,
          sunlight: false,
        ),
      ],
    ],
  );
}

class _GardenResource extends StatelessWidget {
  const _GardenResource({
    required this.label,
    required this.value,
    required this.sunlight,
  });
  final String label;
  final int value;
  final bool sunlight;
  @override
  Widget build(BuildContext context) {
    void explain() => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GardenUiTheme.paper,
        title: Text(
          '$label · 当前余额 $value',
          style: const TextStyle(color: GardenUiTheme.ink),
        ),
        content: Text(
          sunlight ? '完成接阳光练习可获得阳光，用来照顾植物或添置装饰。' : '完成看星星练习可获得星屑，用于解锁高级种子。',
          style: const TextStyle(color: GardenUiTheme.mutedInk),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GardenUiTheme.leaf,
              foregroundColor: GardenUiTheme.paper,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
    return Semantics(
      label: '$label $value，查看用途',
      button: true,
      onTap: explain,
      excludeSemantics: true,
      child: DecoratedBox(
        key: ValueKey(sunlight ? 'resource-sunshine' : 'resource-stardust'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GardenUiTheme.paperTop.withValues(alpha: .90),
              GardenUiTheme.paperBottom.withValues(alpha: .90),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GardenUiTheme.paperEdge),
          boxShadow: const [
            BoxShadow(
              color: GardenUiTheme.softShadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: GardenUiTheme.groundFade,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: explain,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sunlight
                          ? Icons.wb_sunny_rounded
                          : Icons.auto_awesome_rounded,
                      size: 20,
                      color: sunlight
                          ? GardenUiTheme.sunInk
                          : GardenUiTheme.starBottom,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$value',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: GardenUiTheme.ink,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GardenActions extends StatelessWidget {
  const _GardenActions({
    required this.state,
    required this.onStart,
    required this.onShop,
    required this.onHerbarium,
    this.stacked = false,
  });
  final GameState state;
  final ValueChanged<GameIntent> onStart;
  final VoidCallback onShop;
  final VoidCallback onHerbarium;

  /// Full-width practice buttons on their own rows, for a narrow side rail.
  final bool stacked;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;
      final buttonWidth = largeText || stacked
          ? c.maxWidth
          : math.min(180.0, (c.maxWidth - 12) / 2);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: c.maxWidth,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 8,
              children: [
                _GardenUtility(
                  icon: Icons.menu_book_rounded,
                  label: '押花册',
                  onTap: onHerbarium,
                ),
                _GardenUtility(
                  icon: Icons.storefront_rounded,
                  label: '商店',
                  onTap: onShop,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // A narrow rail gives the caption most of the row so it stays on
          // one line, with short rules on either side.
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: GardenUiTheme.paper.withValues(alpha: .55),
                  indent: stacked ? 4 : 12,
                  endIndent: stacked ? 4 : 12,
                ),
              ),
              Expanded(
                flex: stacked ? 9 : 3,
                child: Text(
                  state.quotaRemaining <= 0
                      ? '今日光照已足，明天再练'
                      : '今日可练 ${state.quotaRemaining} 次',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GardenUiTheme.paper,
                    shadows: [
                      Shadow(color: GardenUiTheme.woodEdge, blurRadius: 6),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: GardenUiTheme.paper.withValues(alpha: .55),
                  indent: stacked ? 4 : 12,
                  endIndent: stacked ? 4 : 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: buttonWidth,
                child: GardenPlayButton(
                  label: '接阳光',
                  style: GardenButtonStyle.honey,
                  icon: const Icon(
                    Icons.wb_sunny_rounded,
                    color: GardenUiTheme.ink,
                    size: 26,
                  ),
                  onPressed: () => onStart(const StartCatchDropPressed()),
                ),
              ),
              SizedBox(
                width: buttonWidth,
                child: GardenPlayButton(
                  label: '看星星',
                  style: state.starGazeUnlocked
                      ? GardenButtonStyle.starlight
                      : GardenButtonStyle.disabled,
                  hint: state.starGazeUnlocked ? '看星星 · 40 秒仰头练习' : '首株植物盛开后解锁',
                  icon: GardenStarIcon(locked: !state.starGazeUnlocked),
                  onPressed: () => onStart(const StartStarGazingPressed()),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _GardenUtility extends StatelessWidget {
  const _GardenUtility({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: GardenWood(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 68, minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: GardenUiTheme.paper, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: GardenUiTheme.paper,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The moon remains the game identity. The small lock is a separate, bounded
/// badge; it never replaces or overlays a second copy of the button label.
class GardenStarIcon extends StatelessWidget {
  const GardenStarIcon({super.key, required this.locked});
  final bool locked;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        children: [
          Icon(
            Icons.dark_mode_rounded,
            size: 25,
            color: locked ? GardenUiTheme.mutedInk : GardenUiTheme.paper,
          ),
          if (locked)
            Positioned(
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: GardenUiTheme.paper,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(1),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 12,
                    color: GardenUiTheme.mutedInk,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _GardenPreparation extends StatelessWidget {
  const _GardenPreparation({required this.state, required this.onIntent});
  final GameState state;
  final ValueChanged<GameIntent> onIntent;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(switch (state.phase) {
                GamePhase.countdown => '${state.countdownSeconds}',
                GamePhase.calibrating => '正在校准',
                _ => '暂时无法开始',
              }, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text(
                state.phase == GamePhase.countdown
                    ? (state.kind == GameKind.catchDrop
                          ? '沉肩平视，准备左右轻轻侧头（耳靠向肩）'
                          : '保持自然坐姿，即将开始')
                    : (state.phase == GamePhase.calibrating &&
                              state.kind == GameKind.catchDrop
                          ? '请自然平视屏幕，正在记录你的舒适中立位'
                          : state.statusText),
              ),
              const SizedBox(height: 20),
              if (state.phase == GamePhase.error)
                FilledButton(
                  onPressed: () => onIntent(
                    state.kind == GameKind.catchDrop
                        ? const StartCatchDropPressed()
                        : const StartStarGazingPressed(),
                  ),
                  child: const Text('重试'),
                ),
              TextButton(
                onPressed: () => onIntent(const BackToGardenPressed()),
                child: const Text('返回花园'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final _practiceDialogOpen = Expando<bool>();

Future<void> startGardenPractice(
  BuildContext context,
  GameState state,
  GameIntent intent,
  ValueChanged<GameIntent> onIntent,
) async {
  final navigator = Navigator.of(context);
  if (_practiceDialogOpen[navigator] == true) return;
  _practiceDialogOpen[navigator] = true;
  try {
    await _showPracticePrompt(context, state, intent, onIntent);
  } finally {
    _practiceDialogOpen[navigator] = false;
  }
}

Future<void> _showPracticePrompt(
  BuildContext context,
  GameState state,
  GameIntent intent,
  ValueChanged<GameIntent> onIntent,
) async {
  if (intent is StartStarGazingPressed && !state.starGazeUnlocked) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('星空还在等你'),
        content: const Text('首株植物盛开后解锁看星星。先照顾一株花吧。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
    return;
  }
  if (state.quotaRemaining <= 0) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GardenUiTheme.paper,
        title: const Text(
          '今天的练习次数已用完',
          style: TextStyle(color: GardenUiTheme.ink),
        ),
        content: const Text(
          '让颈部休息一下，明天再来',
          style: TextStyle(color: GardenUiTheme.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return;
  const key = 'l4_camera_consent_shown';
  // Every start explains the actual duration; system permission is requested only
  // by the pose service after this explicit acknowledgement.
  final first = !(prefs.getBool(key) ?? false);
  final isCatch = intent is StartCatchDropPressed;
  final agreed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isCatch ? GardenUiTheme.paper : null,
      title: Text(
        isCatch ? '接阳光 · 40 秒' : '看星星 · 40 秒',
        style: isCatch
            ? const TextStyle(
                color: GardenUiTheme.ink,
                fontWeight: FontWeight.w700,
              )
            : null,
      ),
      content: SingleChildScrollView(
        child: isCatch
            ? _CatchPracticeGuideContent(firstTime: first)
            : Text(
                '将手机放稳，保持自然坐姿。练习时用前置摄像头读取头部动作。'
                '${first ? '画面只在本机处理，不保存、不上传。' : ''}感觉不适可随时停止。',
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            '先不练',
            style: isCatch
                ? const TextStyle(color: GardenUiTheme.mutedInk)
                : null,
          ),
        ),
        FilledButton(
          style: isCatch
              ? FilledButton.styleFrom(
                  backgroundColor: GardenUiTheme.honey,
                  foregroundColor: GardenUiTheme.ink,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('开始练习'),
        ),
      ],
    ),
  );
  if (agreed != true || !context.mounted) return;
  await prefs.setBool(key, true);
  if (!context.mounted) return;
  onIntent(intent);
}

class _CatchPracticeGuideContent extends StatelessWidget {
  const _CatchPracticeGuideContent({required this.firstTime});

  final bool firstTime;

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1. 轻缓侧头移托盘', '耳靠向肩微倾即可，不用用力甩头'),
      ('2. 接蜜色小阳光', '光滴自然直落，漏接不扣分、放轻松就好'),
      ('3. 金阳光保持充能', '大太阳出现时慢呼气保持 2.5 秒，达标可提前完成'),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GardenUiTheme.honeyTint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GardenUiTheme.paperEdge),
          ),
          child: const Text(
            '久坐易肩颈僵硬。耳向肩方向轻轻侧头（不是左右摇头），配合自然呼吸柔和拉开颈侧。',
            style: TextStyle(color: GardenUiTheme.ink, height: 1.45),
          ),
        ),
        const SizedBox(height: 12),
        for (final (title, desc) in steps) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: GardenUiTheme.paperSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: GardenUiTheme.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: GardenUiTheme.mutedInk,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          '慢节奏 · 不惩罚：随时可停，感觉不适立即结束。'
          '${firstTime ? '前置摄像头仅在本机识别头姿，不保存、不上传。' : ''}',
          style: const TextStyle(color: GardenUiTheme.mutedInk, fontSize: 12),
        ),
      ],
    );
  }
}
