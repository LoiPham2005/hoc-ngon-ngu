// =========================================================
//  Build release xong tự mở thư mục chứa APK/AAB (Finder/Explorer).
//  Bỏ qua trên CI (có biến môi trường CI).
// =========================================================

fun openFolder(dir: File) {
    if (System.getenv("CI") != null) return
    if (!dir.exists()) return println("❌ Không thấy thư mục: $dir")
    val os = System.getProperty("os.name").lowercase()
    val command = when {
        "mac" in os -> listOf("open", dir.path)
        "win" in os -> listOf("explorer", dir.path)
        else -> listOf("xdg-open", dir.path)
    }
    runCatching { ProcessBuilder(command).start() }
    println("📁 $dir")
}

// assembleDevRelease → outputs/flutter-apk; bundleDevRelease → outputs/bundle/devRelease
val releaseTask = Regex("(assemble|bundle)([A-Z][A-Za-z0-9]*)Release")

tasks.configureEach {
    val match = releaseTask.matchEntire(name) ?: return@configureEach
    val (kind, flavorName) = match.destructured
    val flavor = flavorName.replaceFirstChar(Char::lowercase)
    val path = if (kind == "assemble") "outputs/flutter-apk" else "outputs/bundle/${flavor}Release"
    doLast { openFolder(layout.buildDirectory.dir(path).get().asFile) }
}
