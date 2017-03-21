#!/bin/bash

### These defaults can be edited  ###
DEFAULT_SOURCE_DIR=${HOME}/src/elmer/elmerfem
DEFAULT_BUILD_PREFIX=${HOME}/src/elmer/builds
DEFAULT_INTSTALL_PREFIX=${HOME}/opt/elmer
DEFAULT_MAKE_NPROC=2
######################################

# {{{ usage function
usage() { 
  echo "A script for building elmer and managing elmer builds. Good for quickly producing build from a branch."
  echo "Usage:" 
  echo -e "\t$0 [-C <preCachefile>] [-t <toolchainfile>] [-c] [-b] [-h] [-i] [-r] [-B <Branch>] [-m] [-n <name>] [-O <cmake_options>] [-M <make_args>]\n";
  echo -e "\tSet environment variables ELMER_SOURCE_DIR, ELMER_BUILD_PREFIX and ELMER_INSTALL_PREFIX. If empty, defaults are used.\n"
  echo "Options:"
  echo -e "\t-C <preCachefile>"
  echo -e "\t\tUse <preCachefile> in cmake configuration step. If \"-\", don't use precache."
  echo ""
  echo -e "\t-t <toolchainfile>"
  echo -e "\t\tUse <toolchainfile> as toolchain file for cmake. Default is no toolchain file."
  echo ""
  echo -e "\t-c"
  echo -e "\t\tOnly run configuration step."
  echo ""
  echo -e "\t-b"
  echo -e "\t\tOnly run build step."
  echo ""
  echo -e "\t-i"
  echo -e "\t\tInstall build."
  echo ""
  echo -e "\t-r"
  echo -e "\t\tRemove old build."
  echo ""
  echo -e "\t -B <Branch>"
  echo -e "\t\tGit checkout to <Branch> prior configure/build."
  echo ""
  echo -e "\t -m"
  echo -e "\t\tPrint lmod module file."
  echo ""
  echo -e "\t -n <name>"
  echo -e "\t\tName build with <name> (Default is "git rev-parse --abbrev-ref HEAD")."
  echo ""
  echo -e "\t -O <cmake_options>"
  echo -e "\t\tAdd <cmake_options> to arguments of cmake call."
  echo ""
  echo -e "\t -M <make_args>"
  echo -e "\t\tAdd <make_args> to arguments of make call."
  echo ""
  echo "CSC internal / 2017-03"
  echo "Complaints not heard at juhani.kataja@csc.fi"
  exit 0; 
}
#}}}

if [ -z "${ELMER_SOURCE_DIR}" ]; then
  ELMER_SOURCE_DIR=${DEFAULT_SOURCE_DIR}
  >&2 echo "ELMER_SOURCE_DIR not set. Defaulting to ${ELMER_SOURCE_DIR}."
fi

if [ -z "$ELMER_BUILD_PREFIX" ]; then
  ELMER_BUILD_PREFIX=${DEFAULT_BUILD_PREFIX}
  >&2 echo "ELMER_BUILD_PREFIX not set. Defaulting to ${ELMER_BUILD_PREFIX}."
fi

if [ -z "$ELMER_INSTALL_PREFIX" ]; then
  ELMER_INSTALL_PREFIX=${DEFAULT_INTSTALL_PREFIX}
  >&2 echo "ELMER_INSTALL_PREFIX not set. Defaulting to ${ELMER_INSTALL_PREFIX}."
fi

if [ -z "$MAKE_NPROC" ]; then
  MAKE_NPROC=${DEFAULT_MAKE_NPROC}
  >&2 echo "MAKE_NPROC not set. Defaulting to ${MAKE_NPROC}."
fi

ELMER_BRANCH=$(cd ${ELMER_SOURCE_DIR} && git rev-parse --abbrev-ref HEAD)
ELMER_BUILD_DIR=${ELMER_BUILD_PREFIX}/$ELMER_BRANCH
ELMER_INSTALL_DIR=${ELMER_INSTALL_PREFIX}/${ELMER_BRANCH}

TOOLCHAIN_ARG=""
PRECACHEFILE="-C $(pwd)/opts-latest.cmake"
ONLY_CONFIG=0
ONLY_BUILD=0
DO_INSTALL=
DO_CLEAN=0

printluamod() {
  echo -e "help(\n[[\nelmerfem ${ELMER_BRANCH} branch\n]])\n"
  echo -e "local version = \"${ELMER_BRANCH}\""
  echo -e "local base = \"${ELMER_INSTALL_DIR}\""
  echo -e "prepend_path(\"PATH\", pathJoin(base, \"bin\"))"
  echo -e "setenv(\"ELMER_HOME\", base)"
}

while getopts "C:chirbB:mn:O:M:t:" opt; do
  case $opt in
    O)
      CMAKE_OPTIONS=${OPTARG}
      >&2 echo "* Extra cmake options: \"${CMAKE_OPTIONS}\""
      ;;
    C)
      if [ "${OPTARG:0:1}" = "/" ]; then
        _PRECACHEFILE=${OPTARG}
        PRECACHEFILE="-C ${OPTARG}"
      elif [ "${OPTARG:0:1}" = "-" ]; then
        _PRECACHEFILE=""
        PRECACHEFILE=""
      else 
        _PRECACHEFILE="$(pwd)/$OPTARG"
        PRECACHEFILE="-C $(pwd)/$OPTARG"
      fi
      if [ ! -z "$_PRECACHEFILE" ]; then
        >&2 echo "* Using ${_PRECACHEFILE} as precache"
      fi
      ;;
    t)
      if [ "${OPTARG:0:1}" = "/" ]; then
        TOOLCHAINFILE=${OPTARG}
        TOOLCHAIN_ARG="-DCMAKE_TOOLCHAIN_FILE=${OPTARG}"
      else 
        TOOLCHAINFILE="$(pwd)/$OPTARG"
        TOOLCHAIN_ARG="-DCMAKE_TOOLCHAIN_FILE=$(pwd)/$OPTARG"
      fi
      >&2 echo "* Using ${TOOLCHAINFILE} as cmake toolchain file."
      ;;
    b)
      ONLY_BUILD=1
      >&2 echo "* Not calling cmake"
      ;;
    c)
      ONLY_CONFIG=1
      >&2 echo "* Not calling make"
      ;;
    h)
      usage
      exit 0
      ;;
    i)
      DO_INSTALL=install
      ;;
    r)
      DO_CLEAN=1
      ;;
    B)
      pushd $ELMER_SOURCE_DIR
      if git checkout $OPTARG; then
        popd
      else
        popd
        exit 1
      fi
      ELMER_BRANCH=$(cd ${ELMER_SOURCE_DIR} && git rev-parse --abbrev-ref HEAD)
      ELMER_BUILD_DIR=${ELMER_BUILD_PREFIX}/$ELMER_BRANCH
      ELMER_INSTALL_DIR=${ELMER_INSTALL_PREFIX}/${ELMER_BRANCH}
      ;;
    n)
      ELMER_BRANCH=$OPTARG
      ELMER_BUILD_DIR=${ELMER_BUILD_PREFIX}/$ELMER_BRANCH
      ELMER_INSTALL_DIR=${ELMER_INSTALL_PREFIX}/${ELMER_BRANCH}
      ;;
    m)
      printluamod
      exit 0
      ;;
    M)
      MAKE_ARGS=${OPTARG}
      >&2 echo "* Extra make arguments: \"${MAKE_ARGS}\""
      ;;
    \?)
      usage
      exit 1
      ;;
  esac
done


>&2 echo -e "BUILD DIRECTORY:\t${ELMER_BUILD_DIR}\nSOURCE DIRECTORY:\t${ELMER_SOURCE_DIR}\nINSTALL DIRECTORY:\t${ELMER_INSTALL_DIR}"

if [ ${DO_CLEAN} -eq 1 ]; then
  ls -l ${ELMER_BUILD_DIR} && rm -Ir ${ELMER_BUILD_DIR}/* && mkdir -p ${ELMER_BUILD_DIR} && cd ${ELMER_BUILD_DIR}
fi

if [ $(ls -a ${ELMER_BUILD_DIR} 2> /dev/null | wc -l) -gt 2 ]; then
  >&2 echo -e "WARNING:\t${ELMER_BUILD_DIR} is not empty."
fi

mkdir -p ${ELMER_BUILD_DIR}

pushd ${ELMER_BUILD_DIR}

if [ $ONLY_BUILD -ne 1 ]; then
  echo cmake ${PRECACHEFILE} ${TOOLCHAIN_ARG} ${CMAKE_OPTIONS} ${ELMER_SOURCE_DIR} -DCMAKE_INSTALL_PREFIX=${ELMER_INSTALL_DIR}
  cmake ${PRECACHEFILE} ${TOOLCHAIN_ARG} ${CMAKE_OPTIONS} ${ELMER_SOURCE_DIR} -DCMAKE_INSTALL_PREFIX=${ELMER_INSTALL_DIR} && ls
fi

if [ $ONLY_CONFIG -eq 1 ]; then
  exit 0
fi

echo "make -j${MAKE_NPROC} ${DO_INSTALL} ${MAKE_ARGS}"
make -j${MAKE_NPROC} ${DO_INSTALL} ${MAKE_ARGS}
popd
exit 0
