import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationId = "com.kakabaev.rick_morty_app.dev"
            signingConfig = signingConfigs.getByName("dev")
            resValue(type = "string", name = "app_name", value = "Rick and Morty App Dev")
        }
        create("stage") {
            dimension = "flavor-type"
            applicationId = "com.kakabaev.rick_morty_app.stage"
            signingConfig = signingConfigs.getByName("stage")
            resValue(type = "string", name = "app_name", value = "Rick and Morty App Stage")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "com.kakabaev.rick_morty_app"
            signingConfig = signingConfigs.getByName("prod")
            resValue(type = "string", name = "app_name", value = "Rick and Morty App")
        }
    }
}