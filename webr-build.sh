#!/bin/bash
set -eu

[[ -z "${1-}" ]] && echo "Error: Must supply tarball" && exit 1
[[ ! -f "$1" ]] && echo "Error: Must supply a tarball file" && exit 1

PKG_NAME=$(basename $1)
[[ $PKG_NAME =~ ([^_]+)_ ]]
PKG_NAME="${BASH_REMATCH[1]-NULL}"
FILENAME=$(basename $1)
FILENAME=${FILENAME##*/}

[[ "$PKG_NAME" == "NULL" ]] && echo "Error: File does not conform to a versioned tarball" && exit 1

ROOT=$(dirname $(realpath "$0"))
ORIG=$(realpath .)
TMP=$(mktemp -d)
TARBALL=$(realpath "$1")

export R_MAKEVARS_USER="${ROOT}/webr-vars.mk"

cd $TMP
tar xvf $TARBALL

# Need to use an empty library and only then copy to the `lib` folder,
# otherwise R might try to load wasm packages from the library and fail
mkdir lib

$R_HOST/bin/R CMD INSTALL --build --library="lib" "${PKG_NAME}" \
  --no-docs \
  --no-test-load \
  --no-staged-install \
  --no-byte-compile

if [ -d "${ROOT}/lib/${PKG_NAME}" ]; then
  rm -rf "${ROOT}/lib/${PKG_NAME}"
fi
mv lib/* ${ROOT}/lib

echo "${ROOT}/lib/${PKG_NAME}.tgz"
echo "${ROOT}/lib/${PKG_NAME}/"
tar -zxvf "${ROOT}/lib/${PKG_NAME}/" "${ROOT}/lib/${PKG_NAME}.tgz"

BIN="${ORIG}/repo/bin/emscripten/contrib/${R_VERSION}/"

mkdir -p $BIN
mv lib/*.tgz $BIN

cd ${ORIG}
rm -rf ${TMP}
