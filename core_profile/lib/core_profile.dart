/// core_profile：画像域数据层。
///
/// W1 为空壳；W2+ 落地 ProfileRepository（标签与偏好本地缓存 +
/// 云端 profile 同步，失败静默重试，本地优先）。
library;
