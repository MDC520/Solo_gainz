# ── Flutter ──────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── Hive ─────────────────────────────────────────────────────────
-keep class com.hive.** { *; }
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ── Supabase / OkHttp / Ktor ─────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**

# ── Kotlin Coroutines ─────────────────────────────────────────────
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# ── Secure Storage ────────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ── Encrypt / Pointy Castle ───────────────────────────────────────
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# ── Image Cropper / Picker ────────────────────────────────────────
-keep class com.yalantis.ucrop.** { *; }
-keep interface com.yalantis.ucrop.** { *; }

# ── Local Notifications ───────────────────────────────────────────
-keep class com.dexterous.** { *; }

# ── Google Fonts (prevent stripping font metadata) ────────────────
-keep class com.google.android.gms.** { *; }

# ── General: keep all annotations ────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
