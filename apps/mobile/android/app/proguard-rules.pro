# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# MapLibre / Mapbox
-keep class org.maplibre.** { *; }
-keep class com.mapbox.** { *; }

# Supabase & serialization rules
-keep class io.supabase.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Ignore missing Play Core classes for R8
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
