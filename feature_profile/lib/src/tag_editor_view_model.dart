import 'dart:async';

import 'package:core_profile/core_profile.dart';
import 'package:core_reminder/core_reminder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'tag_editor_event.dart';
import 'tag_editor_intent.dart';
import 'tag_editor_state.dart';

/// 标签编辑页状态持有者（v8：我的页标签编辑流，原 W3 待办提前）。
///
/// 互斥规则与引导 02 一致（HealthTagCatalog）；
/// 保存 = 落库 + 自动开启对应提醒（加法式）+ 引擎刷新。
class TagEditorViewModel extends Notifier<TagEditorState> {
  final StreamController<TagEditorEvent> _events =
      StreamController<TagEditorEvent>.broadcast();

  Stream<TagEditorEvent> get onEvent => _events.stream;

  @override
  TagEditorState build() {
    ref.onDispose(_events.close);
    _loadInitial();
    return const TagEditorState();
  }

  Future<void> _loadInitial() async {
    final tags = await GetIt.I<HealthTagStore>().load();
    if (!ref.mounted) return;
    state = state.copyWith(selectedTags: tags);
  }

  /// 统一的 Intent 入口（Screen 经 onIntent 回调转发至此）。
  Future<void> handleIntent(TagEditorIntent intent) async {
    switch (intent) {
      case TagToggled(:final label):
        final tags = {...state.selectedTags};
        if (tags.contains(label)) {
          tags.remove(label);
        } else {
          tags.add(label);
          // 互斥（同引导 02 v6）：「只是久坐」与身体状况类互斥。
          if (label == HealthTagCatalog.noConditionTag) {
            tags.removeAll(HealthTagCatalog.bodyConditionTags);
          } else if (HealthTagCatalog.bodyConditionTags.contains(label)) {
            tags.remove(HealthTagCatalog.noConditionTag);
          }
        }
        state = state.copyWith(selectedTags: tags);
      case SavePressed():
        if (state.saving) return;
        state = state.copyWith(saving: true);
        final tags = {...state.selectedTags};
        final store = GetIt.I<HealthTagStore>();
        final repo = GetIt.I<ReminderConfigRepository>();
        await store.save(tags);
        await enableRemindersForTags(tags, repo);
        try {
          await GetIt.I<ReminderEngine>().onSettingsChanged();
        } catch (_) {
          // 引擎未启动（理论不可达）：配置已落库，下次启动生效。
        }
        _events.add(const TagEditorSaved());
    }
  }
}

/// 标签编辑页状态容器（push 进入：pop 后状态随 provider 自动销毁）。
final tagEditorViewModelProvider =
    NotifierProvider<TagEditorViewModel, TagEditorState>(
      TagEditorViewModel.new,
    );
