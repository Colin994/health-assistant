import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tag_editor_event.dart';
import 'tag_editor_screen.dart';
import 'tag_editor_view_model.dart';

/// 标签编辑页跳转入口（架构文档 3.2）。
///
/// 保存成功 pop 返回 true；调用方（我的页）据此刷新标签展示。
class TagEditorScreenRoute extends ConsumerStatefulWidget {
  const TagEditorScreenRoute({super.key});

  /// push 并等待保存结果。
  static Future<bool> push(BuildContext context) {
    return Navigator.of(context)
        .push<bool>(
          MaterialPageRoute<bool>(builder: (_) => const TagEditorScreenRoute()),
        )
        .then((v) => v ?? false);
  }

  @override
  ConsumerState<TagEditorScreenRoute> createState() =>
      _TagEditorScreenRouteState();
}

class _TagEditorScreenRouteState extends ConsumerState<TagEditorScreenRoute> {
  StreamSubscription<TagEditorEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref
        .read(tagEditorViewModelProvider.notifier)
        .onEvent
        .listen((event) {
          if (!mounted) return;
          if (event is TagEditorSaved) {
            Navigator.of(context).pop(true);
          }
        });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(tagEditorViewModelProvider.notifier);
    final state = ref.watch(tagEditorViewModelProvider);
    return TagEditorScreen(
      state: state,
      onIntent: viewModel.handleIntent,
    );
  }
}
