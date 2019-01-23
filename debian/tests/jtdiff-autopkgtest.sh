#!/bin/bash
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

testsuite=$1
shift

if [ -z "${AUTOPKGTEST_TMP+x}" ] || [ -z "${AUTOPKGTEST_ARTIFACTS+x}" ]; then
  echo "Environment variables AUTOPKGTEST_TMP and AUTOPKGTEST_ARTIFACTS must be set" >&2
  exit 1
fi

host_arch=${DEB_HOST_ARCH:-$(dpkg --print-architecture)}

export JTREG_HOME=/usr/share/java
export JT_JAVA="${JT_JAVA:-/usr/lib/jvm/java-11-openjdk-${host_arch}}"

vmname=${VMNAME:-hotspot}

jt_report_tb="/usr/share/doc/openjdk-11-jdk/test-${host_arch}/jtreport-${vmname}.tar.gz"
build_report_dir="${AUTOPKGTEST_TMP}/jtreg-test-output/${testsuite}/JTreport"

if [ ! -f "${jt_report_tb}" ]; then
  echo "Unable to compare jtreg results: no build jtreport found for ${vmname}/${host_arch}."
  echo "Reason: '${jt_report_tb}' does not exist."
  exit 77
fi

# extract testsuite results from original openjdk build
[ -d "${build_report_dir}" ] || \
  tar -xf "${jt_report_tb}" -C "${AUTOPKGTEST_TMP}"

jtdiff -o "${AUTOPKGTEST_ARTIFACTS}/jtdiff.html" "${build_report_dir}" "${AUTOPKGTEST_ARTIFACTS}/JTreport" || true
jtdiff "${build_report_dir}" "${AUTOPKGTEST_ARTIFACTS}/JTreport" | tee "${AUTOPKGTEST_ARTIFACTS}/jtdiff.txt"
