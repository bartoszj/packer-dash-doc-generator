#!/usr/bin/env bash

set -ex

TAG=$1
if [ -z $TAG ]; then
    echo '"TAG" must be specified'
    exit 1
fi

CWD=$(pwd)
BUILD_PATH="${CWD}/build/$TAG"
PACKER_PATH="${CWD}/packer"
WEBSITE_PATH="${PACKER_PATH}/website"

rm -rf "${BUILD_PATH}"
mkdir -p "${BUILD_PATH}"

git clone "https://github.com/hashicorp/packer.git" || true
cd "${PACKER_PATH}"
git fetch --all --prune
git checkout -- .
git checkout "v${TAG}"

cd "${WEBSITE_PATH}"
bundle install

rm Rakefile || true
# cp "${CWD}/Rakefile" .
ln -s "${CWD}/Rakefile" || true

rake

mv Packer.tgz "${BUILD_PATH}"
