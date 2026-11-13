import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

/// 隐私与数据说明页（只读）。
///
/// 对应设置页「隐私与数据说明」条目（此前 onTap 为空）。
/// 重点披露慢植物玩法涉及的**前置摄像头**用途与边界，
/// 以及全部数据的本地存储性质。
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      appBar: AppBar(title: const Text('隐私与数据说明')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageMargin,
            vertical: AppSpacing.md,
          ),
          children: const [
            _Section(
              title: '慢植物花园：前置摄像头',
              lines: [
                '用途：识别头部倾斜角度，把你的颈部动作变成游戏操作。',
                '处理方式：画面在手机本机实时分析，用完即弃。',
                '不保存、不上传、不分享任何照片或视频。',
                '不使用人脸识别、不建立人脸档案；只读取姿态角度数值。',
                '可随时停止：退出游戏即释放相机；未授权则无法开始练习（其他功能不受影响）。',
              ],
            ),
            _Section(
              title: '计步（身体活动）',
              lines: [
                '用途：显示今日步数，作为活动参考。',
                '来源：手机内置计步传感器（Android 活动识别权限）。',
                '仅在应用运行期间统计，不读取其他健康应用数据。',
              ],
            ),
            _Section(
              title: '提醒与通知',
              lines: [
                '用途：久坐 / 喝水 / 护眼倒计时到点提醒。',
                '通知权限、精确闹钟权限均由你授权，可在系统设置随时关闭。',
                '未授予精确闹钟时会自动降级为约 ±15 分钟的宽松提醒，不会重复打扰。',
              ],
            ),
            _Section(
              title: '数据存储位置',
              lines: [
                '全部数据保存在本机（本地偏好存储），不经过服务器。',
                '包含：提醒配置与统计、步数基线、花园进度（阳光 / 星屑 / 地块 / 装饰 / 押花册）。',
                '本应用没有账号体系，无需登录，也不做云同步。',
                '卸载应用即删除全部本地数据。',
              ],
            ),
            _Section(
              title: '我们不做什么',
              lines: [
                '不采集通讯录、位置、短信、通话记录。',
                '不接入任何广告或第三方统计 SDK。',
                '不上传任何个人数据。',
              ],
            ),
            _Section(
              title: '健康声明',
              lines: [
                '本应用提供的拉伸与颈部活动建议属于一般健康促进，不构成医疗诊断或治疗。',
                '如已有颈椎疾病或急性疼痛，请先咨询医生；游戏中可随时暂停或退出。',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('· ', style: AppTypography.body),
                  Expanded(
                    child: Text(
                      line,
                      style: AppTypography.body.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 隐私页路由。
class PrivacyScreenRoute extends StatelessWidget {
  const PrivacyScreenRoute({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PrivacyScreenRoute()),
    );
  }

  @override
  Widget build(BuildContext context) => const PrivacyScreen();
}
