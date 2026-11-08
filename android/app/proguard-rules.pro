# Flutter's JNI entry points and generated plugin registrant use @Keep.
# Keep annotation and plugin consumer rules are supplied by their libraries and
# Flutter's Gradle plugin; do not retain the entire io.flutter package.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
# WorkManager persists this class name across APK updates.
-keep class com.leanbitlab.ltvL.PermissionRecoveryWorker { *; }
