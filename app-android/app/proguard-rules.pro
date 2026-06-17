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
-keep interface com.algoritmico.passepartout.PassepartoutWrapperProtocol {
    native <methods>;
}

# The native core calls these handlers by method name through GetMethodID.
# Keep both the fun-interface methods and their generated lambda/object
# implementors so R8 cannot rename the callback entry points.
-keep interface io.partout.abi.PartoutCompletionCallback {
    public void onComplete(int, java.lang.String);
}
# JNI entry points are exported with static Java_* symbols, and the native
# tunnel backend also receives this controller object and calls into it by name
# through GetMethodID. Keep the class and both sides of that method contract.
-keep class io.partout.vpn.JNITunnelController {
    native <methods>;
    public long setDelegate(long);
    public int setTunnel(java.lang.String);
    public void configureSockets(int[]);
    public void onSnapshot(java.lang.String);
    public void clearTunnel(boolean);
    public void cancelTunnel(java.lang.String);
}
