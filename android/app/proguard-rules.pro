# Firebase Messaging — keep the background-message callback & entry points
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-keep class com.google.firebase.messaging.** { *; }

# flutter_local_notifications — keep receiver & boot-completed handler
-keep class com.dexterous.** { *; }

# Flutter engine & plugins (R8 release builds)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Firebase-related classes that use reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Keep Gson (used by Firebase internally)
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
