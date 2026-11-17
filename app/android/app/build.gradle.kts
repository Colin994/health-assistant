import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// release 签名配置（key.properties / keystore 均不入版本库）。
// 缺文件时回退 debug 签名，保证 `flutter run --release` 与其他开发者可构建。
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "dev.healthassistant.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(
                    keystoreProperties["storeFile"] as String
                )
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications 要求开启 core library desugaring。
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.healthassistant.app"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // health plugin requires 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 双渠道：dev（开发版，可与正式版共存）/ master（正式用户版）。
    // Dart 侧经 base_utils 的 BuildEnv（flavor / BUILD_ENV）联动隐藏 W2/L4 等开发字样。
    buildFeatures {
        // AGP 默认关闭 flavor 的 resValue（app_name），此处显式开启。
        resValues = true
    }
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "健康助手测试版")
        }
        create("master") {
            dimension = "env"
            resValue("string", "app_name", "健康助手")
        }
    }

    buildTypes {
        release {
            // 有 release keystore 时用它签名（正式发布）；否则回退 debug
            // 以便本地 `flutter run --release` 仍可用。
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // ML Kit 反射加载的内部类必须 keep(见 proguard-rules.pro),
            // 否则 release 下相机姿态推理崩 NPE。
            proguardFile("proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
