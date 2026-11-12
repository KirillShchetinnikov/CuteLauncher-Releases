# Flutter's JNI entry points and generated plugin registrant use @Keep.
# Keep annotation and plugin consumer rules are supplied by their libraries and
# Flutter's Gradle plugin; do not retain the entire io.flutter package.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
# WorkManager persists this class name across APK updates.
-keep class com.leanbitlab.ltvL.PermissionRecoveryWorker { *; }

# SMBJ's event bus discovers annotated connection/session cleanup methods.
-keepattributes RuntimeVisibleAnnotations
-keepclassmembers class com.hierynomus.smbj.** {
    @net.engio.mbassy.listener.Handler <methods>;
}

# Optional desktop APIs: this client explicitly uses NTLM, and SMBJ handlers
# have no EL conditions. Android does not provide Kerberos/JGSS or Java EL.
-dontwarn javax.el.BeanELResolver
-dontwarn javax.el.ELContext
-dontwarn javax.el.ELResolver
-dontwarn javax.el.ExpressionFactory
-dontwarn javax.el.FunctionMapper
-dontwarn javax.el.ValueExpression
-dontwarn javax.el.VariableMapper
-dontwarn org.ietf.jgss.GSSContext
-dontwarn org.ietf.jgss.GSSCredential
-dontwarn org.ietf.jgss.GSSException
-dontwarn org.ietf.jgss.GSSManager
-dontwarn org.ietf.jgss.GSSName
-dontwarn org.ietf.jgss.Oid
