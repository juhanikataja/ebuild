#!/bin/bash
BUILDNAME=${1:-}
>&2 echo Buildname = ${BUILDNAME}

TESTLOGFILE=${2:-testlog.txt}
if test ! -f $TESTLOGFILE; then
  >&2 echo "File $TESTLOGFILE not found. Adding only test outputs."
  TESTLOGFILE=
fi

# Checks
if test ! -f Makefile; then
  >&2 echo "No Makefile found. Exiting."
  exit 1
fi

if test ! -f CMakeCache.txt; then
  >&2 echo "This is not a cmake build directory. Exiting."
  exit 1
fi

MAKEFILEDATE=$(stat --format=%x Makefile | cut -d" " -f 1)

TESTPASSEDS=$(find . -maxdepth 4 -name "TEST.PASSED*")

TESTOUTPUTS=$(find . -maxdepth 4 -name "test-*.log")
if test -z "$TESTOUTPUTS"; then
  >&2 echo "No test output files. Exiting."
  exit 1
fi

REVISION=$(grep 'ELMER_FEM_REVISION:STRING' CMakeCache.txt | cut -d"=" -f 2)

if test ! -z "$BUILDNAME"; then
  BUILDNAME=${BUILDNAME}-
  >&2 echo Buildname = ${BUILDNAME}
fi


tar cvvfz "Elmer-${BUILDNAME}${REVISION}-${MAKEFILEDATE}.tar.gz" ${TESTOUTPUTS} ${TESTPASSEDS} ${TESTLOGFILE} CMakeCache.txt
