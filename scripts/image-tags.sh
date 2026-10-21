#!/usr/bin/env bash
set -euo pipefail

image=${1:?Usage: image-tags.sh IMAGE FLAVOR}
flavor=${2:?Usage: image-tags.sh IMAGE FLAVOR}

case "$flavor" in
    yii2|laravel) ;;
    *) echo "Unknown flavor: $flavor" >&2; exit 1 ;;
esac

version_output=$(docker run --rm --entrypoint nginx "$image:$flavor" -v 2>&1)
if [[ ! $version_output =~ ^nginx\ version:\ nginx/([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    echo "Unexpected Nginx version: $version_output" >&2
    exit 1
fi
nginx_version=${BASH_REMATCH[1]}

printf '%s\n' "$image:$flavor" "$image:$nginx_version-$flavor"
if [[ $flavor == yii2 ]]; then
    printf '%s\n' "$image:latest" "$image:$nginx_version"
fi
