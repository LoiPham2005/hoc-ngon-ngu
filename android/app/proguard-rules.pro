# ════════════════════════════════════════════════════════════════
# ProGuard / R8 rules — lingua (release: isMinifyEnabled = true)
# ════════════════════════════════════════════════════════════════
#
# Chỉ ghi rule mà thư viện KHÔNG tự mang. Không cần thêm cho:
# - Flutter embedding + plugin: Flutter Gradle plugin tự thêm flutter_proguard_rules.pro.
# - Firebase, Google Mobile Ads, RevenueCat, Sentry, Gson, kotlinx.coroutines: AAR có consumer rules.
# - Enum values()/valueOf, Parcelable CREATOR, native methods: có trong proguard-android-optimize.txt.
# Đừng `-keep class com.google.** { *; }` kiểu cả gói — tắt shrink cả SDK, APK to ra vô ích.
# Thêm plugin dùng reflection mà README yêu cầu rule → ghi vào đây.

# ─── Crashlytics / Sentry: stack trace đọc được (map lại bằng mapping.txt) ──
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ─── flutter_local_notifications ──────────────────────────────────
# Lưu lịch thông báo bằng Gson (reflection) → giữ model của plugin + generic Signature.
-keepattributes Signature
-keep class com.dexterous.** { *; }

# ─── Play Core ────────────────────────────────────────────────────
# Flutter embedding tham chiếu play.core (deferred components). App không dùng
# deferred components → không có dep này, chỉ cần bảo R8 bỏ qua.
-dontwarn com.google.android.play.core.**
