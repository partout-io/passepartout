# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# JNI entry points are exported with static Java_* symbols, so their Kotlin
# owner and method names must remain stable after R8.
-keep class com.algoritmico.passepartout.helpers.NativeLibraryWrapper {
    native <methods>;
}

# The native core calls these handlers by method name through GetMethodID.
# Keep both the fun-interface methods and their generated lambda/object
# implementors so R8 cannot rename the callback entry points.
-keep interface com.algoritmico.passepartout.helpers.ABIEventHandler {
    public void onEvent(java.lang.String);
}
-keep class * implements com.algoritmico.passepartout.helpers.ABIEventHandler {
    public void onEvent(java.lang.String);
}
-keep interface com.algoritmico.passepartout.helpers.ABIConnectionStatusHandler {
    public void onStatus(java.lang.String);
}
-keep class * implements com.algoritmico.passepartout.helpers.ABIConnectionStatusHandler {
    public void onStatus(java.lang.String);
}
-keep interface com.algoritmico.passepartout.helpers.ABICompletionCallback {
    public void onComplete(int, java.lang.String);
}
-keep class * implements com.algoritmico.passepartout.helpers.ABICompletionCallback {
    public void onComplete(int, java.lang.String);
}

# The native tunnel backend receives this object and calls into it by name.
-keep class io.partout.jni.AndroidTunnelController {
    public *;
}
