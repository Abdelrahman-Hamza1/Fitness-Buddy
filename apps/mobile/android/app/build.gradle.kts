plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// --- Release signing (S06 plan D4, A6; docs/runbooks/android-signing.md) ---
// The stable release key comes from the environment (CI secrets, or the laptop's
// release.env via tools/scripts/build-android.sh); the keystore never enters the
// repo. A release signed with any other key can't update an installed build, and
// uninstalling deletes the phone's local data. So a release build without the key
// fails unless FB_ALLOW_DEBUG_SIGNING=1: build-android.sh sets it on purpose (forks,
// Dependabot, a fresh laptop) and names those outputs *-debugkey.*.
val releaseKeyEnvNames =
    listOf("FB_ANDROID_KEYSTORE_PASSWORD", "FB_ANDROID_KEY_ALIAS", "FB_ANDROID_KEY_PASSWORD")
val releaseKeystorePath: String? =
    providers.environmentVariable("FB_KEYSTORE_PATH").orNull?.takeIf { it.isNotBlank() }
val releaseKeyValues: Map<String, String?> =
    releaseKeyEnvNames.associateWith { name ->
        providers.environmentVariable(name).orNull?.takeIf { it.isNotBlank() }
    }
if (releaseKeystorePath != null) {
    // Half a configuration is a mistake, not a reason to fall back silently.
    val missing = releaseKeyValues.filterValues { it == null }.keys
    if (missing.isNotEmpty()) {
        throw GradleException(
            "FB_KEYSTORE_PATH is set but these are missing: ${missing.joinToString()}. " +
                "Set all four release signing variables, or none (debug signing).",
        )
    }
    if (!file(releaseKeystorePath).isFile) {
        throw GradleException("FB_KEYSTORE_PATH points to a file that does not exist.")
    }
}
val signWithReleaseKey = releaseKeystorePath != null
val buildsRelease =
    gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
if (!signWithReleaseKey && buildsRelease) {
    if (providers.environmentVariable("FB_ALLOW_DEBUG_SIGNING").orNull != "1") {
        throw GradleException(
            "Release build without the release key (FB_KEYSTORE_PATH is not set). Build with " +
                "`make build-android`, which reads ~/.fitness-buddy/keys/release.env, or set the " +
                "four FB_* signing variables (docs/runbooks/android-signing.md). " +
                "FB_ALLOW_DEBUG_SIGNING=1 signs with the debug key instead: such a build can't " +
                "update an installed Fitness Buddy.",
        )
    }
    // quiet level: Flutter runs Gradle with -q, which hides warn().
    logger.quiet(
        "warning: FB_ALLOW_DEBUG_SIGNING=1: this release build is signed with the DEBUG key " +
            "and can't update an installed Fitness Buddy.",
    )
}

android {
    // Application ID (S06 plan D5, owner 2026-10-15): permanent once on Play.
    namespace = "io.github.abdelrahmanhamza1.fitnessbuddy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        // AGP 9 turns resValue off by default; the launcher labels below use it.
        resValues = true
    }

    defaultConfig {
        applicationId = "io.github.abdelrahmanhamza1.fitnessbuddy"
        // sentry_flutter 10 needs API 26 (Android 8.0); Flutter 3.47's default is 24.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // From pubspec.yaml's version, or --build-name / --build-number.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Patrol integration tests (S06 plan D18, patrol_test/): its runner
        // starts the app and runs each Dart test as one instrumented test
        // (src/androidTest/.../MainActivityTest.java). clearPackageData: every
        // test starts on a fresh install (no preferences, no cached config).
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    testOptions {
        // Each test in its own instrumentation process, so one crash can't
        // take the others down (Patrol's documented setup).
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    // Flavors (S06 plan D5, D6): side by side on one phone, told apart by the
    // launcher label. The Dart side reads its flavor from
    // --dart-define-from-file=config/<flavor>.json. No versionNameSuffix (A8): the
    // update gate compares the plain version.
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "FB Dev")
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "FB Staging")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Fitness Buddy")
        }
    }

    signingConfigs {
        if (signWithReleaseKey) {
            create("release") {
                storeFile = file(releaseKeystorePath!!)
                storePassword = releaseKeyValues.getValue("FB_ANDROID_KEYSTORE_PASSWORD")
                keyAlias = releaseKeyValues.getValue("FB_ANDROID_KEY_ALIAS")
                keyPassword = releaseKeyValues.getValue("FB_ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.getByName(if (signWithReleaseKey) "release" else "debug")
            // Explicit, and checked on the built APK (tools/scripts/apk_hardening_check.py).
            isDebuggable = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // The test orchestrator above (Patrol's documented version; patrol_cli
    // warns about 1.5.0). Only in the androidTest APK, never in the app.
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
