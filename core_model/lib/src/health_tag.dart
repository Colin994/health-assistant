/// 用户健康标签。
class HealthTag {
  const HealthTag({
    required this.code,
    this.subCodes = const [],
  });

  /// 标签码：cervical_spondylosis / lumbar_strain / eye_strain / none。
  final String code;

  /// 预留：严重程度等细分维度。
  final List<String> subCodes;
}
