import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationId = "com.loipham.lingua.dev"
            resValue(type = "string", name = "app_name", value = "Lingua Dev")
        }
        create("stg") {
            dimension = "flavor-type"
            applicationId = "com.loipham.lingua.stg"
            resValue(type = "string", name = "app_name", value = "Lingua Stg")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "com.loipham.lingua"
            resValue(type = "string", name = "app_name", value = "Lingua")
        }
    }

    buildFeatures.resValues = true
}