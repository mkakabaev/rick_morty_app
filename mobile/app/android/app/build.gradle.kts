// cSpell: ignore flavorizr proguard androiddebugkey

import java.util.Properties
// import com.android.build.gradle.internal.dsl.SigningConfig
import com.android.build.api.dsl.SigningConfig

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kakabaev.rick_morty_app"
    compileSdk = maxOf(flutter.compileSdkVersion, 37)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // AGP 9 disables resValues by default. Flavorizr still injects app_name via resValue.
    buildFeatures {
        resValues = true
    }

    defaultConfig {
        applicationId = "com.kakabaev.rick_morty_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Create default signing configs. 
    signingConfigs {

        // For debug version, we use standard SDK's debug.keystore file for all builds.
        // This is safe as all builds are not for public distribution.
        // This is already defined in signingConfigs and looks like this:
        // create("debug") {
        //     storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
        //     storePassword = "android"
        //     keyAlias = "androiddebugkey"
        //     keyPassword = "android"
        // }

        fun flavorReleaseRequestedInThisBuild(flavorName: String): Boolean {
            // Invoked tasks only (e.g. assembleStageRelease), not every variant.
            // Empty during IDE sync. Debug and profile use the SDK debug keystore.
            val tasks = gradle.startParameter.taskNames.map { it.lowercase() }
            if (tasks.isEmpty()) return false
            val needle = flavorName.lowercase()
            return tasks.any { it.contains(needle) && it.contains("release") }
        }

        fun addSigningConfigForFlavor(flavorName: String) {
            val signingConfigName = "${flavorName}"
            create(signingConfigName) {
                // println("Adding signing config for flavor '$flavorName'")
                val keystoreProps = Properties()
                val keystoresDirectory = "../../../other/secrets/android/keystores"
                val keystorePropsFile = file("$keystoresDirectory/${flavorName}.keystore.properties")

                if (keystorePropsFile.exists()) {
                    keystoreProps.load(keystorePropsFile.inputStream())
                    storeFile = file("$keystoresDirectory/${keystoreProps.getProperty("storeFile")}")
                    storePassword = keystoreProps.getProperty("storePassword")
                    keyAlias = keystoreProps.getProperty("keyAlias")
                    keyPassword = keystoreProps.getProperty("keyPassword")
                } else if (flavorReleaseRequestedInThisBuild(flavorName)) {
                    error(
                        "Keystore properties file not found for flavor '$flavorName' at $keystorePropsFile. " +
                            "Please generate the keystore using the provided script before building a release of this flavor."
                    )
                } else {
                    // Other flavors are still registered (productFlavors reference them).
                    logger.warn(
                        "No keystore for flavor '$flavorName' at $keystorePropsFile (not required for this task)."
                    )
                }
            }
        }

        // Warning: for new flavors, you need to add the signing config manually here. flavorizr will not do it.
        addSigningConfigForFlavor("dev")
        addSigningConfigForFlavor("stage")
        addSigningConfigForFlavor("prod")
    }

    buildTypes {
        debug {
            // applicationIdSuffix = ".debug"
            // isDebuggable = true
            signingConfig = signingConfigs.getByName("debug")
        }
        
        release {
            // isMinifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // Signing config is created and assigned by flavor
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

// Print build configuration information
afterEvaluate {

    fun printSigningConfigForFlavor(signingConfig: SigningConfig?) {
        // println(" • Signing Name: ${signingConfig?.name}")
        println(" • Keystore: ${signingConfig?.storeFile?.path ?: "-"}")
        println(" • Keystore Alias: ${signingConfig?.keyAlias ?: "-"}")
    }

    // Add build summary to all assemble tasks
    tasks.matching { it.name.startsWith("assemble") }.configureEach {
        doFirst {
            val divider = "-".repeat(60)
            println("$divider")
            println("BUILD CONFIGURATION SUMMARY")
            println("$divider")
            println(" • App ID: ${android.defaultConfig.applicationId}")
            println(" • App Version: ${android.defaultConfig.versionName} (${android.defaultConfig.versionCode})")
            println(" • Target SDK: ${android.defaultConfig.targetSdk}")
            println(" • Min SDK: ${android.defaultConfig.minSdk}")
            println(" • Compile SDK: ${android.compileSdk}")
            println(" • NDK Version: ${android.ndkVersion}")
            println(" • Java Version: ${android.compileOptions.sourceCompatibility}")          
            println(" • Kotlin Version: ${org.jetbrains.kotlin.config.KotlinCompilerVersion.VERSION}")
            println(" • Kotlin JVM Version: ${android.compileOptions.targetCompatibility}")
            println(" • Gradle Version: ${gradle.gradleVersion}")
            println(" • AGP Version: ${com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION}")
            println(" • Build Tools Version: ${android.buildToolsVersion}")
            println(" • Build Name: ${name}")

            val match = Regex("^assemble([A-Z][a-zA-Z]*)(Debug|Release|Profile)$").find(name)
            if (match == null) {
                error("Unable to parse the build name: ${name}")
            }
            val flavor = match.groupValues[1]
            var buildType = match.groupValues[2]
            println(" • Flavor: $flavor")
            println(" • Build Type: $buildType")
            
            var buildTypeName = buildType.lowercase()
            val isDebug = buildTypeName == "debug"
            val isRelease = buildTypeName == "release"
            var isProfile = buildTypeName == "profile"
            
            if (isDebug || isProfile) {
               printSigningConfigForFlavor(android.buildTypes.findByName(buildTypeName)?.signingConfig)
            }
            if (isRelease) {                         
                printSigningConfigForFlavor(android.signingConfigs.getByName(flavor.lowercase()))
            }
           
            println("$divider")
        }
    }
}

// ----- BEGIN flavorDimensions (autogenerated by flutter_flavorizr) -----
apply { from("flavorizr.gradle.kts") }
// ----- END flavorDimensions (autogenerated by flutter_flavorizr) -----