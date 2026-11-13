import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'garden_scene.dart';

/// 花畦锚点手动校准(dev):拖动移动/右下角手柄缩放四框对齐场景白框,
/// 「复制常量」导出 `_isoBedSpecs` Dart 代码,回贴到 game_screen.dart。
class GardenBedCalibrationScreen extends StatefulWidget {
  const GardenBedCalibrationScreen({super.key});

  @override
  State<GardenBedCalibrationScreen> createState() =>
      _GardenBedCalibrationScreenState();
}

class _CalSpec {
  _CalSpec(this.center, this.size);

  Offset center; // 图内归一化
  Size size; // 图内归一化
}

class _GardenBedCalibrationScreenState
    extends State<GardenBedCalibrationScreen> {
  List<_CalSpec> _specs = [
    _CalSpec(const Offset(0.494, 0.474), const Size(0.254, 0.095)),
    _CalSpec(const Offset(0.289, 0.544), const Size(0.297, 0.110)),
    _CalSpec(const Offset(0.744, 0.555), const Size(0.293, 0.088)),
    _CalSpec(const Offset(0.516, 0.629), const Size(0.297, 0.112)),
  ];
  final List<Color> _colors = const [
    Color(0xFFE53935), // 后
    Color(0xFFFB8C00), // 左
    Color(0xFF1E88E5), // 右
    Color(0xFF8E24AA), // 前
  ];
  static const _names = ['后', '左', '右', '前'];

  int? _dragIndex;
  bool _resizing = false;
  GardenIsoMetrics? _metrics;

  double get _scale => _metrics?.scale ?? 1;

  Offset _toNorm(Offset screenDelta) =>
      screenDelta / (_metrics == null ? 1 : kGardenIsoImageSize.width * _scale);

  void _onPanStart(DragStartDetails d) {
    final metrics = _metrics;
    if (metrics == null) {
      return;
    }
    // 手柄优先(右下角 24px 内)。
    for (var i = _specs.length - 1; i >= 0; i--) {
      final r = metrics.rect(_specs[i].center, _specs[i].size);
      final handle = Offset(r.right, r.bottom);
      if ((d.localPosition - handle).distance <= 26) {
        setState(() {
          _dragIndex = i;
          _resizing = true;
        });
        return;
      }
    }
    for (var i = _specs.length - 1; i >= 0; i--) {
      if (metrics.rect(_specs[i].center, _specs[i].size)
          .contains(d.localPosition)) {
        setState(() {
          _dragIndex = i;
          _resizing = false;
        });
        return;
      }
    }
    _dragIndex = null;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final i = _dragIndex;
    final metrics = _metrics;
    if (i == null || metrics == null) {
      return;
    }
    final dNorm = _toNorm(d.delta);
    setState(() {
      if (_resizing) {
        _specs[i].size = Size(
          (_specs[i].size.width + dNorm.dx).clamp(0.05, 0.6),
          (_specs[i].size.height + dNorm.dy).clamp(0.03, 0.3),
        );
      } else {
        _specs[i].center = Offset(
          (_specs[i].center.dx + dNorm.dx).clamp(0.05, 0.95),
          (_specs[i].center.dy + dNorm.dy).clamp(0.05, 0.95),
        );
      }
    });
  }

  String get _exportCode {
    final buf = StringBuffer('const _isoBedSpecs = [\n');
    for (var i = 0; i < _specs.length; i++) {
      final c = _specs[i].center;
      final s = _specs[i].size;
      buf.write(
        '  _IsoBedSpec(Offset(${c.dx.toStringAsFixed(3)}, '
        '${c.dy.toStringAsFixed(3)}), Size(${s.width.toStringAsFixed(3)}, '
        '${s.height.toStringAsFixed(3)})), // ${_names[i]}\n',
      );
    }
    buf.write('];');
    return buf.toString();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _exportCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('常量已复制,回贴到 game_screen.dart')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('花畦锚点校准'),
        actions: [
          TextButton(
            onPressed: _copy,
            child: const Text('复制常量'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重置',
            onPressed: () => setState(() => _specs = [
                  _CalSpec(const Offset(0.494, 0.474),
                      const Size(0.254, 0.095)),
                  _CalSpec(const Offset(0.289, 0.544),
                      const Size(0.297, 0.110)),
                  _CalSpec(const Offset(0.744, 0.555),
                      const Size(0.293, 0.088)),
                  _CalSpec(const Offset(0.516, 0.629),
                      const Size(0.297, 0.112)),
                ]),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _metrics = GardenIsoMetrics(
                  screenSize: Size(constraints.maxWidth, constraints.maxHeight),
                );
                return GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        kGardenIsoAssets[GardenTimeOfDay.noon]!,
                        fit: BoxFit.cover,
                      ),
                      CustomPaint(
                        painter: _CalibrationPainter(
                          metrics: _metrics!,
                          specs: _specs,
                          colors: _colors,
                          names: _names,
                          dragIndex: _dragIndex,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              '拖动框=移动;拖右下角圆点=缩放。对齐白框后点「复制常量」。',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Colors.black54,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Text(
                _exportCode,
                style: const TextStyle(
                  color: Colors.lightGreenAccent,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalibrationPainter extends CustomPainter {
  _CalibrationPainter({
    required this.metrics,
    required this.specs,
    required this.colors,
    required this.names,
    required this.dragIndex,
  });

  final GardenIsoMetrics metrics;
  final List<_CalSpec> specs;
  final List<Color> colors;
  final List<String> names;
  final int? dragIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < specs.length; i++) {
      final r = metrics.rect(specs[i].center, specs[i].size);
      final color = colors[i];
      final isDragging = dragIndex == i;
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(10)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isDragging ? 3 : 2
          ..color = color,
      );
      // 右下角缩放手柄。
      canvas.drawCircle(
        Offset(r.right, r.bottom),
        isDragging ? 12 : 9,
        Paint()..color = color,
      );
      textPainter.text = TextSpan(
        text: names[i],
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(r.left + 4, r.top + 2));
    }
  }

  @override
  bool shouldRepaint(_CalibrationPainter oldDelegate) => true;
}
