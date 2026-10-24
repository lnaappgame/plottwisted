import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.lnaapp.plottwisted"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requis par flutter_local_notifications (rappels locaux).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Version de test installable à côté de celle du Play Store (sans la
        // remplacer ni toucher à ses données) : PT_TEST_BUILD=1 flutter build apk.
        // Elle reprend l'ancien identifiant de développement, toujours
        // enregistré dans google-services.json, et s'appelle « PT test ».
        val testBuild = System.getenv("PT_TEST_BUILD") == "1"
        applicationId = if (testBuild) "com.example.cine_devinette" else "com.lnaapp.plottwisted"
        manifestPlaceholders["appLabel"] = if (testBuild) "PT test" else "Plot Twist(ed)"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Force une version récente : google_mobile_ads tire transitivement
    // androidx.work:work-runtime 2.7.0 (2021), qui plante au lancement en
    // release sur Android récent ("Failed to create an instance of
    // androidx.work.impl.WorkDatabase") — la base Room générée par cette
    // vieille version n'est pas compatible avec le runtime WorkManager
    // moderne. Sans lien avec le contenu du jeu : bug de dépendance pure.
    implementation("androidx.work:work-runtime:2.11.1")
}
