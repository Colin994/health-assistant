import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'game_state.dart';
import 'game_intent.dart';
import 'garden_scene.dart';
import 'garden/garden_scene_layout.dart';
import 'garden/garden_ui_theme.dart';
import 'catch_drop/catch_drop_board.dart';
import 'catch_drop/catch_drop_session.dart';
import 'star_gazing/star_gazing_board.dart';
import 'star_gazing/star_gazing_session.dart';

// ============ 练习区 ============

class GamePlayArea extends StatelessWidget {
  const GamePlayArea({super.key, required this.state, required this.onIntent});

  final GameState state;
  final void Function(GameIntent intent) onIntent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = GardenUiTheme.of(context);
    final paused = state.phase == GamePhase.paused;
    final catchSnap = state.catchSnapshot;
    final starSnap = state.starSnapshot;
    final total = switch (state.kind) {
      GameKind.catchDrop => CatchDropConfig.standard.sessionDuration.inSeconds,
      GameKind.starGazing =>
        StarGazingConfig.standard.sessionDuration.inSeconds,
    };
    final elapsed =
        catchSnap?.elapsed.inSeconds ?? starSnap?.elapsed.inSeconds ?? 0;
    final remaining = (total - elapsed).clamp(0, total);
    final canFinishEarly =
        catchSnap?.canFinishEarly ?? starSnap?.canFinishEarly ?? false;
    final isCatch = state.kind == GameKind.catchDrop;
    // 结算遮罩期间隐藏底部动作按钮(避免透过遮罩露出)。
    final showFinishEarly =
        canFinishEarly && !paused && state.phase != GamePhase.result;
    final progressRatio = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 全屏玩法背景(接阳光采用明媚水粉林间草地，看星星暂保持原图)。
        Image(
          image: AssetImage(
            isCatch
                ? 'assets/game/catch_clearing.jpg'
                : 'assets/game/backdrop_catch.png',
          ),
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
        ),
        _PlayStage(
          night: !isCatch,
          builder: (context, framed) => SafeArea(
            child: Column(
              children: [
                // 顶部:HUD 胶囊(右侧预留 68dp 给外层退出圆形按钮)。
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 68, 0),
                  child: isCatch
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _CatchHudPill(text: '剩余 ${remaining}s'),
                              _CatchHudPill(
                                text: '${catchSnap?.score ?? 0} 分',
                              ),
                              if (showFinishEarly)
                                FilledButton(
                                  onPressed: () =>
                                      onIntent(const FinishEarlyPressed()),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: GardenUiTheme.honey,
                                    foregroundColor: GardenUiTheme.ink,
                                    minimumSize: const Size(44, 44),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: const Text(
                                    '提前完成',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: g.hud,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 16,
                                    color: remaining <= 10
                                        ? context.tokens.dangerText
                                        : g.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${remaining}s',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: remaining <= 10
                                          ? context.tokens.dangerText
                                          : g.onHud,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                ),
                if (isCatch)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 4,
                        backgroundColor: GardenUiTheme.paper.withValues(
                          alpha: 0.55,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          GardenUiTheme.honeyDeep,
                        ),
                      ),
                    ),
                  ),
                if (!isCatch && state.statusText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: g.hud,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        state.statusText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: g.onHud,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: isCatch && catchSnap != null
                        ? _UniformStage(
                            child: CatchDropBoard(
                              snapshot: catchSnap,
                              remainingSeconds: remaining,
                              totalSeconds: total,
                              events: state.catchEvents,
                              eventSeq: state.catchEventSeq,
                              tickMs: CatchDropConfig
                                  .standard
                                  .tickInterval
                                  .inMilliseconds,
                            ),
                        )
                        : starSnap != null
                        ? StarGazingBoard(
                            snapshot: starSnap,
                            headPitch: state.latestPitch,
                            remainingSeconds: remaining,
                            totalSeconds: total,
                            backdrop: !framed,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                // 底部固定高度槽位：接阳光用作单一引导胶囊（避免双胶囊叠放），
                // 看星星保持原提前完成槽位不变。
                if (isCatch)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Center(
                        child: (paused || state.statusText.isNotEmpty)
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: (catchSnap?.goldenCharging ?? false)
                                      ? GardenUiTheme.honey
                                      : GardenUiTheme.paper.withValues(
                                          alpha: 0.92,
                                        ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: (catchSnap?.goldenCharging ?? false)
                                        ? GardenUiTheme.honeyEdge
                                        : GardenUiTheme.paperEdge,
                                    width: 1.25,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: GardenUiTheme.softShadow,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  paused
                                      ? '已暂停 · 回到画面前保持放松'
                                      : state.statusText,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: GardenUiTheme.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  )
                else ...[
                  SizedBox(
                    height: 64,
                    child: Center(
                      child: IgnorePointer(
                        ignoring: !showFinishEarly,
                        child: AnimatedOpacity(
                          opacity: showFinishEarly ? 1 : 0,
                          duration: resolveMotion(context, AppMotion.standard),
                          child: AnimatedScale(
                            scale: showFinishEarly ? 1 : 0.85,
                            duration: resolveMotion(context, AppMotion.standard),
                            child: FilledButton.icon(
                              onPressed: () =>
                                  onIntent(const FinishEarlyPressed()),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('提前完成'),
                              style: FilledButton.styleFrom(
                                backgroundColor: g.sunshine,
                                foregroundColor: g.hud,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (paused)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '已暂停 · 回到画面前保持放松',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: g.onHud,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 练习舞台的最大宽度：宽窗(平板、桌面窗口)上把 HUD、进度条、棋盘和底部
/// 提示收进居中的一列，背景仍铺满窗口。手机竖屏宽度低于此值，布局不变。
const double kPlayStageWidth = 640;

/// 安全区内的可用尺寸 → 舞台宽度。矮窗口(高度不足 600，即手机横屏)铺满：
/// 那里竖向空间本就紧张，收窄会让光滴的下落距离过短。
double playStageWidthFor(Size safe) =>
    safe.height >= 600 ? math.min(safe.width, kPlayStageWidth) : safe.width;

/// 看星星夜空按完整构图(高度铺满窗口)时的宽度。
double nightSceneWidthFor(double height) =>
    height * kStarNightImageSize.width / kStarNightImageSize.height;

/// 练习舞台。窗口比舞台宽时，看星星的夜空改为铺满窗口，不再只是棋盘的底。
class _PlayStage extends StatelessWidget {
  const _PlayStage({required this.night, required this.builder});

  final bool night;

  /// `framed` 表示舞台比窗口窄。
  final Widget Function(BuildContext context, bool framed) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final padding = MediaQuery.paddingOf(context);
        final safe = Size(
          c.maxWidth - padding.horizontal,
          c.maxHeight - padding.vertical,
        );
        final nightWidth = nightSceneWidthFor(c.maxHeight);
        final width = playStageWidthFor(safe);
        // A staged star practice never reaches past its own backdrop.
        final stageWidth = night && width < safe.width
            ? math.min(width, nightWidth)
            : width;
        final framed = stageWidth < safe.width;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (night && framed)
              GardenFramedScene(
                // 完整构图：月亮、云、树与栅栏都在，不按窗口宽度裁切。
                width: math.min(c.maxWidth, nightWidth),
                bands: kStarNightEdgeBands,
                imageSize: kStarNightImageSize,
                imageTop: 0,
                imageHeight: c.maxHeight,
                child: const StarNightBackdrop(),
              ),
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: stageWidth + padding.horizontal,
                height: c.maxHeight,
                child: SafeArea(child: builder(context, framed)),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 宽舞台上棋盘仍按手机宽度排布，再整体等比放大：托盘、光滴与判定窗口
/// 保持手机上的比例。玩法坐标本身是归一化的，判定逻辑不变。
class _UniformStage extends StatelessWidget {
  const _UniformStage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final scale = CatchDropBoard.stageScaleFor(c.maxWidth);
      if (scale == 1) return child;
      return Transform.scale(
        scale: scale,
        child: OverflowBox(
          minWidth: 0,
          maxWidth: c.maxWidth / scale,
          minHeight: 0,
          maxHeight: c.maxHeight / scale,
          child: child,
        ),
      );
    },
  );
}

class _CatchHudPill extends StatelessWidget {
  const _CatchHudPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: GardenUiTheme.paper.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GardenUiTheme.paperEdge, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: GardenUiTheme.softShadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: GardenUiTheme.ink,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
