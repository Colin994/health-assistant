import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final directory = Directory('build/garden-panel-review');
    await directory.create(recursive: true);
    await File('${directory.path}/$name').writeAsBytes(bytes);
    return true;
  },
  responseDataCallback: null,
);
