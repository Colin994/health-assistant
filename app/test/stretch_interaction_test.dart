import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_stretch/feature_stretch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const action = StretchAction(name: '肩部画圈', durationLabel: '60 秒');

  testWidgets('拉伸反馈按钮分别发送对应反馈，关闭和本次不做各自独立', (tester) async {
    final intents = <StretchIntent>[];
    var gardenOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: StretchScreen(
          state: const StretchState(),
          onIntent: intents.add,
          onOpenGarden: () => gardenOpened = true,
        ),
      ),
    );

    const feedback = {
      '做完了': StretchFeedback.done,
      '稍后提醒': StretchFeedback.later,
      '今天别提醒': StretchFeedback.muteToday,
      '关闭此类提醒': StretchFeedback.neverAgain,
    };
    for (final entry in feedback.entries) {
      await tester.tap(find.text(entry.key));
      expect(
        intents.removeLast(),
        isA<FeedbackSelected>().having(
          (intent) => intent.feedback,
          '反馈',
          entry.value,
        ),
      );
    }
    await tester.tap(find.text('本次不做'));
    expect(intents.removeLast(), isA<SkipThisPressed>());
    await tester.tap(find.byTooltip('关闭'));
    expect(intents.removeLast(), isA<ClosePressed>());
    await tester.tap(find.text('或者去花园接阳光'));
    expect(gardenOpened, isTrue);
    expect(intents, isEmpty);
  });

  testWidgets('打开动作详情后可开始、暂停、完成并返回', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: StretchScreen(
          state: const StretchState(actions: [action]),
          onIntent: (_) {},
          onActionTapped: ActionDetailScreenRoute.push,
        ),
      ),
    );
    await tester.tap(find.text(action.name));
    await tester.pumpAndSettle();
    expect(find.byType(ActionDetailScreen), findsOneWidget);
    expect(find.text('1:00'), findsOneWidget);

    await tester.tap(find.text('开始'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0:59'), findsOneWidget);
    await tester.tap(find.text('暂停'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('0:59'), findsOneWidget);

    await tester.tap(find.text('开始'));
    await tester.pump(const Duration(seconds: 59));
    expect(find.text('0:00'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '完成'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.byType(StretchScreen), findsOneWidget);
    expect(find.byType(ActionDetailScreen), findsNothing);
  });
}
