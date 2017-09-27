#!/bin/bash

set -e

ENGINE_BRANCH=master

domain=docker.io
urlpath=go-docker
importpath="$domain/$urlpath"
package=docker

sed=$(which gsed) || sed=$(which sed)
dir=$(pwd)
rm -rf *.go api
tmp=${1:-/tmp/go-docker.tmp}

set -x
cd "$tmp"

[ ! -d docker ] && git clone --depth 1 -b "$ENGINE_BRANCH" https://github.com/docker/docker

pushd docker
for folder in api client; do
	find "$folder" -name '*.go' -type f -exec sed -i'' -E 's#github.com/docker/docker/api(/?)#'"${importpath}"'/api\1#g' {} \;
	find "$folder" -name '*.go' -type f -exec sed -i'' -E 's#github.com/docker/docker/client(/?)#'"${importpath}"'\1#g' {} \;
done
cp client/*.go "$dir/"
cp -rf api "$dir/"
rm -rf \
    "$dir/api/server" \
    "$dir/swarm_get_unlock_key_test.go" \
    "$dir/api/errdefs" \
    "$dir/api/templates" \
    "$dir/api/types/backend" \
    "$dir/api/swagger*"
popd

pushd "$dir"
find . -name '*.go' -depth 1 -print | xargs $sed -i'' -E 's,^package client\b,package '"${package}"' // import "'${importpath}'",g'
find . -name '*.go' -depth 1 -print | xargs $sed -i'' -E 's,^Package client\b,Package '"${package}"',g'
sed -i'' -E 's#client(\.NewEnvClient\(\))#docker\1#g' client.go
popd

cd "$dir"
# reset README.md
git checkout README.md

function strip_doc() {
	tail -n +$(grep -n '^package ' "$1" | cut -d: -f1) "$1" > "$1".new
	mv "$1".new "$1"
}

# replace documentation
strip_doc client.go
cp scripts/files/*.go .
