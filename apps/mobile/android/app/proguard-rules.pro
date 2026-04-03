# Flutter-specific ProGuard rules
# Keep Flutter wrapper and JNI entry points
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.**

# Keep Google Play Services (used for geofencing)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep WorkManager classes
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Keep the app's own package (geofence receiver/worker)
-keep class com.yourcompany.whileyoureout.** { *; }

# Keep Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-dontwarn kotlinx.coroutines.**

# Suppress notes about missing references in external libs
-dontnote **

# Keep line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
