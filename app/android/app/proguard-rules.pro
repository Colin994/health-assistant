# ---- ML Kit (face detection) ----
# R8 在 release 构建会裁剪/重命名 ML Kit 依赖反射加载的内部类,
# 表现为 processImage 抛 InputImageConverterError + NullPointerException
# (debug 正常、release 必崩)。整体保留,禁止裁剪。
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_face.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**
