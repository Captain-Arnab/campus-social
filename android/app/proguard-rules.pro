# Firebase Messaging — keep the background-message callback & entry points
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-keep class com.google.firebase.messaging.** { *; }

# flutter_local_notifications — keep receiver & boot-completed handler
-keep class com.dexterous.** { *; }

# Keep Firebase-related classes that use reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Keep Gson (used by Firebase internally)
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
