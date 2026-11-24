import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_state.dart';
import 'game_intent.dart';
import 'game_play_area.dart';
import 'game_result_overlay.dart';
import 'garden/garden_view.dart';
import 'garden/garden_ui_theme.dart';
import 'garden_scene.dart';

/// Presentation-only shell. State remains owned by GameViewModel.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.state, required this.onIntent});
  final GameState state;
  final ValueChanged<GameIntent> onIntent;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((e) => e is! GardenUiTheme),
          GardenUiTheme.standard,
        ],
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value:
            (state.phase == GamePhase.idle &&
                    state.gardenTime != GardenTimeOfDay.night) ||
                (state.phase != GamePhase.idle &&
                    state.kind == GameKind.catchDrop)
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: GardenUiTheme.paper,
          body: Stack(
            fit: StackFit.expand,
            children: [
              switch (state.phase) {
                GamePhase.playing || GamePhase.paused || GamePhase.result =>
                  GamePlayArea(state: state, onIntent: onIntent),
                _ => GardenView(state: state, onIntent: onIntent),
              },
              if (state.phase != GamePhase.result)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: GameRoundButton(
                        key: const ValueKey('garden-exit'),
                        icon: Icons.close_rounded,
                        semanticLabel: '退出',
                        onDark:
                            state.phase != GamePhase.idle &&
                            state.kind == GameKind.starGazing,
                        onTap: () => onIntent(const ExitPressed()),
                      ),
                    ),
                  ),
                ),
              if (state.phase == GamePhase.result)
                GameResultOverlay(state: state, onIntent: onIntent),
            ],
          ),
        ),
      ),
    );
  }
}

/// 游戏风圆形按钮:半透明底 + 白/深 icon + 细描边 + 按下缩放。
///
/// 用于沉浸式页面(替代 AppBar 的返回/退出)。
class GameRoundButton extends StatefulWidget {
  const GameRoundButton({
    required this.icon,
    required this.onTap,
    this.semanticLabel,
    this.onDark = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  /// 深色背景上(onDark=true 用白字/浅底,浅色背景反之)。
  final bool onDark;

  @override
  State<GameRoundButton> createState() => _GameRoundButtonState();
}

class _GameRoundButtonState extends State<GameRoundButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: MediaQuery.disableAnimationsOf(context)
              ? 1
              : _pressed
              ? 0.9
              : 1,
          duration: resolveMotion(context, AppMotion.feedback),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.onDark
                  ? GardenUiTheme.standard.hud
                  : GardenUiTheme.paper,
              borderRadius: radius,
              border: Border.all(
                color: widget.onDark
                    ? GardenUiTheme.standard.secondary
                    : GardenUiTheme.paperEdge,
                width: 1.5,
              ),
              boxShadow: AppShadows.cardSubtle,
            ),
            child: Icon(
              widget.icon,
              size: 22,
              color: widget.onDark
                  ? GardenUiTheme.standard.onHud
                  : GardenUiTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}
