#include <jni.h>

// Partout requires this only extern.
JavaVM *jvm;

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)reserved;
    jvm = vm;
    return JNI_VERSION_1_6;
}
