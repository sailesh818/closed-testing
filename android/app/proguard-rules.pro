# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase (Auth, Firestore, Core)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Prevent removal of your app’s model classes (if using Firestore)
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
}

# Keep JSON models (if using Gson)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Retain annotations
-keepattributes *Annotation*

# Keep your app’s main activity
-keep class com.closedtesting.closed_testing.MainActivity { *; }
