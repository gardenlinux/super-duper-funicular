#!/bin/bash
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

host_arch="${DEB_HOST_ARCH:-$(dpkg --print-architecture)}"
jdk_path=$(echo /usr/lib/jvm/java-24-openjdk-amd64 | sed "s/-[^-]*$/-$host_arch/")

cat <<EOF > ${AUTOPKGTEST_TMP}/test.cpp
#include <jni.h>

int main(){
    JavaVM *jvm;
    JNIEnv *env;
    JavaVMInitArgs vm_args;
    vm_args.version = JNI_VERSION_1_8;
    vm_args.nOptions = 0;
    vm_args.ignoreUnrecognized = false;
    JNI_CreateJavaVM(&jvm, (void**)&env, &vm_args);
}
EOF

find ${jdk_path}/lib -name libjvm.so | while read -r x; do
    jvmdir="$(dirname ${x})"
    echo ${jvmdir}
    g++ ${AUTOPKGTEST_TMP}/test.cpp \
        -I${jdk_path}/include -I${jdk_path}/include/linux \
        -L${jvmdir} -ljvm
    LD_LIBRARY_PATH=${jvmdir} ./a.out && echo "${jvmdir} - vm created"
done
