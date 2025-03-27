plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.pet_wellness_app"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.pet_wellness_app"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        multiDexEnabled = true
    }

    buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
    debug {
        isMinifyEnabled = false
        isShrinkResources = false
    }
    }

    applicationVariants.configureEach {
        val variant = this
        outputs.configureEach {
            if (this is com.android.build.gradle.internal.api.ApkVariantOutputImpl) {
                this.outputFileName = "app-${variant.name}.apk"
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.10.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
    implementation("androidx.multidex:multidex:2.0.1")
}

apply(plugin = "com.google.gms.google-services")

// Custom task to copy Debug APK to Flutter's expected location
tasks.register<Copy>("copyDebugApkToFlutterDir") {
    val sourceFile = layout.buildDirectory.dir("outputs/apk/debug/app-debug.apk").get().asFile
    val destDir = file("${project.rootDir}/../build/app/outputs/flutter-apk")

    doFirst {
        println("CopyDebugApkToFlutterDir: Source file exists: ${sourceFile.exists()} at ${sourceFile.absolutePath}")
        println("CopyDebugApkToFlutterDir: Destination directory: ${destDir.absolutePath}")
    }

    from(sourceFile)
    into(destDir)

    doLast {
        println("CopyDebugApkToFlutterDir: Copy completed. Destination file exists: ${(destDir.resolve("app-debug.apk")).exists()}")
    }
}

// Custom task to copy Release APK to Flutter's expected location
tasks.register<Copy>("copyReleaseApkToFlutterDir") {
    val sourceFile = layout.buildDirectory.dir("outputs/apk/release/app-release.apk").get().asFile
    val destDir = file("${project.rootDir}/../build/app/outputs/flutter-apk")

    doFirst {
        println("CopyReleaseApkToFlutterDir: Source file exists: ${sourceFile.exists()} at ${sourceFile.absolutePath}")
        println("CopyReleaseApkToFlutterDir: Destination directory: ${destDir.absolutePath}")
    }

    from(sourceFile)
    into(destDir)

    doLast {
        println("CopyReleaseApkToFlutterDir: Copy completed. Destination file exists: ${(destDir.resolve("app-release.apk")).exists()}")
    }
}

// Delay configuration until tasks are available
project.afterEvaluate {
    tasks.findByName("assembleDebug")?.finalizedBy("copyDebugApkToFlutterDir")
    tasks.findByName("assembleRelease")?.finalizedBy("copyReleaseApkToFlutterDir")
}