import 'package:core_health/core_health.dart';
import 'package:flutter_test/flutter_test.dart';

PoseSample s(
  int t, {
  double p = 0,
  double r = 0,
  double y = 0,
  bool face = true,
}) {
  return PoseSample(
    pitch: p,
    roll: r,
    yaw: y,
    timestampMs: t,
    faceDetected: face,
  );
}

void main() {
  group('averagePose(校准零点均值)', () {
    test('只统计有人脸的样本', () {
      final zero = averagePose([
        s(0, p: 10, r: -5),
        s(100, p: 20, r: 5, face: false), // 无脸帧不参与
        s(200, p: 30, r: 15),
      ]);
      expect(zero.pitch, 20);
      expect(zero.roll, 5);
      expect(zero.timestampMs, 200);
    });

    test('全部无脸则抛错(校准失败路径)', () {
      expect(
        () => averagePose([s(0, face: false), s(100, face: false)]),
        throwsArgumentError,
      );
    });
  });

  group('FacePresenceGate(离画判定,方案 §3.1)', () {
    test('无脸未超 1 秒不触发', () {
      final gate = FacePresenceGate();
      expect(gate.feed(s(0)), isNull);
      expect(gate.feed(s(500, face: false)), isNull);
      expect(gate.feed(s(999, face: false)), isNull);
    });

    test('无脸满 1 秒边缘触发一次 PoseFaceLost', () {
      final gate = FacePresenceGate();
      gate.feed(s(0));
      expect(gate.feed(s(1000, face: false)), isNull);
      expect(gate.feed(s(1001, face: false)), isA<PoseFaceLost>());
      expect(gate.feed(s(1200, face: false)), isNull); // 只触发一次
    });

    test('离画后回画触发 PoseFaceBack,再次离画可重复触发', () {
      final gate = FacePresenceGate();
      gate.feed(s(0));
      gate.feed(s(1000, face: false));
      expect(gate.feed(s(1001, face: false)), isA<PoseFaceLost>());
      expect(gate.feed(s(2000)), isA<PoseFaceBack>());
      expect(gate.feed(s(2600)), isNull); // 正常在画不触发
      gate.feed(s(3000, face: false));
      expect(gate.feed(s(4001, face: false)), isA<PoseFaceLost>());
    });

    test('从未见过人脸时不触发离画(避免冷启动误报)', () {
      final gate = FacePresenceGate();
      expect(gate.feed(s(0, face: false)), isNull);
      expect(gate.feed(s(5000, face: false)), isNull);
    });

    test('relativeTo:相对角 = 当前 - 零点(§6.4 判定口径)', () {
      final zero = PoseSample(
        pitch: 5,
        roll: -3,
        yaw: 2,
        timestampMs: 0,
      );
      final now = s(100, p: 8, r: 1, y: -4);
      final rel = now.relativeTo(zero);
      expect(rel.pitch, 3);
      expect(rel.roll, 4);
      expect(rel.yaw, -6);
    });
  });
}
