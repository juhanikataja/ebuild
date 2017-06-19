#!/bin/bash
BUILDNAME=${1:-}

TESTLOGFILE=${2:-testlog.txt}
if $(test ! -f $TESTLOGFILE); then
  >&2 echo "File $TESTLOGFILE not found. Adding only test outputs."
  TESTLOGFILE=
fi

if $(test -f CMakeCache.txt); then
  TESTOUTPUTS=$(find . -name "test-*.log" -maxdepth 4)
  if [ -n $TESTOUTPUTS ]; then
    >&2 echo "No test output files. Exiting."
    exit 1
  fi
  REVISION=$(grep 'ELMER_FEM_REVISION:STRING' CMakeCache.txt | cut -d"=" -f 2)
  if [ -n $BUILNAME ]; then
    BUILDNAME=${BUILDNAME}-
  fi
  tar cvvfz Elmer-${BUILDNAME}${REVISION}-$(date -I).tar.gz ${TESTOUTPUTS} ${TESTLOGFILE} CMakeCache.txt
else
  >&2 echo "This is not a cmake build directory. Exiting."
  exit 1
fi
