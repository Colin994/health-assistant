import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game_state.dart';
import '../game_intent.dart';
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
    final stats = _GardenStats(state: state);
    final actions = _GardenActions(
      state: state,
      onHerbarium: () => _panel(context, GardenPanel.herbarium),
      onShop: () => _panel(context, GardenPanel.shop),
      onStart: (intent) =>
          startGardenPractice(context, state, intent, onIntent),
    );
    Widget scene({bool immersive = false}) => GardenSceneView(
      plots: state.plots,
      decorations: state.decorations,
      time: state.gardenTime,
      immersive: immersive,
      onPlot: (i) => _panel(
        context,
        state.plots[i] == null ? GardenPanel.seed : GardenPanel.plant,
        plotIndex: i,
      ),
    );
    return LayoutBuilder(
      builder: (context, c) {
        final expandedText = MediaQuery.textScalerOf(context).scale(14) > 19;
        if (c.maxWidth < 840 && c.maxHeight >= 600 && !expandedText) {
          // The world fills the screen; the interface is a handful of floating
          // objects, not three vertically stacked application sections.
          return Stack(
            fit: StackFit.expand,
            children: [
              scene(immersive: true),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: stats,
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: actions,
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        // Keep one world transform even when the controls need to scroll.
        // A second, focus-cropped scene creates a visible rectangular seam.
        return Stack(
          fit: StackFit.expand,
          children: [
            scene(immersive: true),
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
                          child: stats,
                        ),
                        const SizedBox(height: 280),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: actions,
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

class _GardenStats extends StatelessWidget {
  const _GardenStats({required this.state});
  final GameState state;
  static const _resourceTop = 60.0;
  static const _resourceHeight = 44.0;
  static const _resourceGap = 8.0;

  @override
  Widget build(BuildContext context) {
    final expandedText = MediaQuery.textScalerOf(context).scale(14) > 19;
    final showStardust = state.starGazeUnlocked || state.stardustTotal > 0;
    final title = const _GardenTitleSign();
    final resources = _GardenResources(
      state: state,
      showStardust: showStardust,
    );
    final status = state.statusText.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GardenPaper(
              child: Semantics(liveRegion: true, child: Text(state.statusText)),
            ),
          );
    if (expandedText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: AlignmentDirectional.centerStart, child: title),
          const SizedBox(height: 16),
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
  const _GardenTitleSign();

  @override
  Widget build(BuildContext context) => Transform.rotate(
    key: const ValueKey('garden-title-rotation'),
    angle: -3 * math.pi / 180,
    child: GardenWood(
      hanging: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Text(
          '慢植物',
          style: const TextStyle(
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
        title: Text('$label · 当前余额 $value'),
        content: Text(
          sunlight ? '完成接阳光练习可获得阳光，用来照顾植物或添置装饰。' : '完成看星星练习可获得星屑，用于解锁高级种子。',
        ),
        actions: [
          TextButton(
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
      child: Material(
        key: ValueKey(sunlight ? 'resource-sunshine' : 'resource-stardust'),
        color: GardenUiTheme.paper,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: explain,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        : GardenUiTheme.mutedInk,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '$value',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: GardenUiTheme.ink,
                        fontWeight: FontWeight.w600,
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
    );
  }
}

class _GardenActions extends StatelessWidget {
  const _GardenActions({
    required this.state,
    required this.onStart,
    required this.onShop,
    required this.onHerbarium,
  });
  final GameState state;
  final ValueChanged<GameIntent> onStart;
  final VoidCallback onShop;
  final VoidCallback onHerbarium;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;
      final buttonWidth = largeText
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
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: GardenUiTheme.paper.withValues(alpha: .55),
                  indent: 12,
                  endIndent: 12,
                ),
              ),
              Expanded(
                flex: 3,
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
                  indent: 12,
                  endIndent: 12,
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
                  primary: true,
                  icon: const Icon(
                    Icons.wb_sunny_rounded,
                    color: GardenUiTheme.ink,
                    size: 28,
                  ),
                  onPressed: () => onStart(const StartCatchDropPressed()),
                ),
              ),
              SizedBox(
                width: buttonWidth,
                child: GardenPlayButton(
                  label: '看星星',
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
      child: Material(
        color: GardenUiTheme.groundFade,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: GardenUiTheme.paper, size: 26),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: GardenUiTheme.paper,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
          const Icon(
            Icons.dark_mode_rounded,
            size: 25,
            color: GardenUiTheme.ink,
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
                    color: GardenUiTheme.ink,
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
                    ? '保持自然坐姿，即将开始'
                    : state.statusText,
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
  final agreed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        intent is StartStarGazingPressed ? '看星星 · 40 秒' : '接阳光 · 40 秒',
      ),
      content: SingleChildScrollView(
        child: Text(
          '将手机放稳，保持自然坐姿。练习时用前置摄像头读取头部动作。'
          '${first ? '画面只在本机处理，不保存、不上传。' : ''}感觉不适可随时停止。',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('先不练'),
        ),
        FilledButton(
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
