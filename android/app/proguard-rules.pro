# App Entry Point
-keep class com.carrommaster.carrom_master.** { *; }

# Flutter Wrapper Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Annotations
-keep @androidx.annotation.Keep class * { *; }
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <fields>;
    @androidx.annotation.Keep <methods>;
}

# Flutter Deferred Components / Play Store Split Compat
-dontwarn com.google.android.play.core.**

# Google Mobile Ads & UMP
-keep class io.flutter.plugins.googlemobileads.** { *; }
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.ump.**

# WebView Flutter (transitive dependency of google_mobile_ads)
-keep class io.flutter.plugins.webviewflutter.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Audioplayers
-dontwarn xyz.luan.audioplayers.**
-keep class xyz.luan.audioplayers.** { *; }

# Video Player
-dontwarn io.flutter.plugins.videoplayer.**
-keep class io.flutter.plugins.videoplayer.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Shared Preferences & JNI / Pigeon
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
