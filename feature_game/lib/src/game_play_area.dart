import 'package:flutter/material.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'game_state.dart';
import 'garden/garden_ui_theme.dart';
import 'game_intent.dart';
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
    // 结算遮罩期间隐藏底部动作按钮(避免透过遮罩露出)。
    final showFinishEarly =
        canFinishEarly && !paused && state.phase != GamePhase.result;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 全屏玩法背景(沉浸式:顶栏/底栏也落在场景上,无白边割裂)。
        const Image(
          image: AssetImage('assets/game/backdrop_catch.png'),
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
        ),
        SafeArea(
          child: Column(
            children: [
              // 顶部:倒计时 HUD 胶囊(左侧),退出按钮由外层浮于右上。
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 68, 0),
                child: Row(
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
                              // 最后 10 秒变红加粗,提示收尾。
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
              if (state.statusText.isNotEmpty)
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
                  child: state.kind == GameKind.catchDrop && catchSnap != null
                      ? CatchDropBoard(
                          snapshot: catchSnap,
                          remainingSeconds: remaining,
                          totalSeconds: total,
                          events: state.catchEvents,
                          eventSeq: state.catchEventSeq,
                          tickMs: CatchDropConfig
                              .standard
                              .tickInterval
                              .inMilliseconds,
                        )
                      : starSnap != null
                      ? StarGazingBoard(
                          snapshot: starSnap,
                          headPitch: state.latestPitch,
                          remainingSeconds: remaining,
                          totalSeconds: total,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              // 底部:提前完成按钮占固定高度槽位(隐藏时保留空间),
              // 避免按钮出现/消失挤压棋盘,把篮子顶起来。
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
                          onPressed: () => onIntent(const FinishEarlyPressed()),
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
          ),
        ),
      ],
    );
  }
}
