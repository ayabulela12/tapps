# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Application class
-keep public class com.tapps.appmaniazar.Application

# Keep View bindings
-keepclassmembers class * extends android.view.View {
    void set*(***);
    *** get*();
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    private static final java.io.ObjectStreamField[] serialVersionUID;
    static final long serialVersionUID;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes and resources
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Remove logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Firebase and Play Services (keep only what's needed)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Remove debug information
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Optimize the code
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Remove unused code
-printusage
-whyareyoukeeping class *

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep the specific native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep application classes that are dynamically loaded
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference

# Remove debug logs in release builds
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
}

# Keep the -native and -annotations classes
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
-keepclasseswithmembernames class * {
    @androidx.annotation.* <methods>;
}
-keepclasseswithmembernames class * {
    @androidx.annotation.* <fields>;
}

# Keep the -keepnames option
-keepnames class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep the -keepclasseswithmembernames option
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep the -keepclasseswithmembers option
-keepclasseswithmembers class * {
    @androidx.annotation.* <methods>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.* <fields>;
}
