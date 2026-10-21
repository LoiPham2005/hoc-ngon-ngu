import com.android.build.api.variant.ApplicationAndroidComponentsExtension
import java.text.Normalizer
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

// =========================================================
//  Đặt tên APK/AAB bản RELEASE:
//    <tên-app>-release[-<abi>]-v<versionName>+<versionCode>-<yyyy-MM-dd_HHhmm>-<sha7>.apk|.aab
//  - APK: thêm 1 bản tên đẹp vào outputs/flutter-apk/, GIỮ app-<flavor>-release.apk
//    (`flutter build apk` cần đúng tên đó, đổi tên là báo build lỗi).
//  - AAB: đổi tên tại outputs/bundle/<variant>/ (Flutter tìm AAB bất kỳ trong thư mục này).
//  - Debug/profile giữ nguyên tên mặc định.
//  - sha7 = commit build ra file (kể cả prod — biết bản trên store build từ commit nào).
// =========================================================

/** "AppDev 1" → "appdev-1" (bỏ dấu, bỏ ký tự lạ). */
fun String.toSafeFileName(): String =
    Normalizer.normalize(this, Normalizer.Form.NFD)
        .replace(Regex("\\p{InCombiningDiacriticalMarks}"), "")
        .replace("Đ", "D").replace("đ", "d")
        .replace(Regex("[^a-zA-Z0-9\\s_-]"), "")
        .trim()
        .replace(Regex("[\\s_]+"), "-")
        .lowercase()

/** Tên app của flavor — lấy `app_name` trong flavorizr.gradle.kts (file do flavorizr sinh). */
val flavorizrGradle = file("flavorizr.gradle.kts").takeIf { it.exists() }?.readText().orEmpty()

fun flavorAppName(flavor: String): String =
    Regex("""create\("$flavor"\)\s*\{[^}]*?app_name[^)]*?value\s*=\s*"([^"]+)"""", RegexOption.DOT_MATCHES_ALL)
        .find(flavorizrGradle)?.groupValues?.get(1)
        ?: "${rootProject.name}-$flavor"

/** Lấy 1 lần lúc configure (sha không đổi trong 1 build). Không phải git repo → "nogit". */
val gitSha: String = runCatching {
    ProcessBuilder("git", "rev-parse", "--short=7", "HEAD")
        .directory(rootDir.parentFile) // gốc dự án Flutter (Gradle chạy ở android/)
        .start().inputStream.bufferedReader().readText().trim()
}.getOrNull()?.takeIf { it.isNotEmpty() } ?: "nogit"

fun timestamp(): String = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HH'h'mm"))

/** Gọi lúc build (không phải lúc configure) để timestamp đúng thời điểm. */
fun releaseFileName(app: String, abi: String?, versionName: String?, versionCode: Int?, sha: String): String =
    "$app-release${abi?.let { "-$it" }.orEmpty()}-v$versionName+$versionCode-${timestamp()}$sha"

extensions.getByType<ApplicationAndroidComponentsExtension>().onVariants { variant ->
    if (variant.buildType != "release") return@onVariants

    val flavor = variant.flavorName.orEmpty()
    val app = flavorAppName(flavor).toSafeFileName()
    val sha = "-$gitSha"
    val main = variant.outputs.first()

    val variantTask = variant.name.replaceFirstChar { it.uppercase() }

    // APK — chạy SAU assemble (lúc Flutter đã copy APK sang flutter-apk/). Danh sách APK vừa build
    // + versionCode từng ABI lấy từ output-metadata.json của AGP (flutter-apk/ còn sót file build cũ).
    val apkDir = listOf("outputs/apk", flavor.ifEmpty { null }, "release").filterNotNull().joinToString("/")
    val copyApk = tasks.register("copyNamedApk$variantTask") {
        doLast {
            val dir = layout.buildDirectory.dir("outputs/flutter-apk").get().asFile
            val metadata = layout.buildDirectory.file("$apkDir/output-metadata.json").get().asFile
            if (!metadata.exists()) return@doLast
            // Xoá bản tên đẹp của lần build trước cho đỡ đầy thư mục.
            dir.listFiles { f -> f.name.startsWith("$app-release") && "-v" in f.name }?.forEach { it.delete() }

            @Suppress("UNCHECKED_CAST")
            val elements = (groovy.json.JsonSlurper().parse(metadata) as Map<String, Any?>)["elements"] as List<Map<String, Any?>>
            elements.forEach { element ->
                @Suppress("UNCHECKED_CAST")
                val abi = (element["filters"] as List<Map<String, Any?>>)
                    .firstOrNull { it["filterType"] == "ABI" }?.get("value") as String?
                // Tên Flutter đặt: app[-<abi>]-<flavor>-release.apk
                val apk = File(dir, listOfNotNull("app", abi, flavor.ifEmpty { null }, "release").joinToString("-") + ".apk")
                if (!apk.exists()) return@forEach
                val name = releaseFileName(app, abi, element["versionName"] as String?, element["versionCode"] as Int?, sha)
                apk.copyTo(File(dir, "$name.apk"), overwrite = true)
                println("✅ APK → $name.apk")
            }
        }
    }
    tasks.matching { it.name == "assemble$variantTask" }.configureEach { finalizedBy(copyApk) }

    // AAB — không đổi tên qua output được → đổi ngay sau khi task bundle chạy xong.
    val defaultAab = listOf("app", flavor.ifEmpty { null }, "release").filterNotNull().joinToString("-") + ".aab"
    tasks.matching { it.name == "bundle$variantTask" }.configureEach {
        doLast {
            val dir = layout.buildDirectory.dir("outputs/bundle/${variant.name}").get().asFile
            val aab = File(dir, defaultAab).takeIf { it.exists() } ?: return@doLast
            // Xoá AAB đã đổi tên của lần build trước — Flutter lấy AAB bất kỳ trong thư mục này.
            dir.listFiles { f -> f.extension == "aab" && f != aab }?.forEach { it.delete() }
            val renamed = File(dir, "${releaseFileName(app, null, main.versionName.orNull, main.versionCode.orNull, sha)}.aab")
            if (aab.renameTo(renamed)) println("✅ AAB → ${renamed.name}")
        }
    }
}
