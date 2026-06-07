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
