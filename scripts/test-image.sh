#!/usr/bin/env bash
set -euo pipefail

image=${1:?Usage: test-image.sh IMAGE FLAVOR}
flavor=${2:?Usage: test-image.sh IMAGE FLAVOR}
php_image=${PHP_TEST_IMAGE:-php:8.5-fpm-alpine}

case "$flavor" in
    yii2) document_root=web ;;
    laravel) document_root=public ;;
    *) echo "Unknown flavor: $flavor" >&2; exit 1 ;;
esac

version_output=$(docker run --rm --entrypoint nginx "$image" -v 2>&1)
echo "$version_output"
[[ $version_output =~ ^nginx\ version:\ nginx/[0-9]+\.[0-9]+\.[0-9]+$ ]]

test_directory=$(mktemp -d "${TMPDIR:-/tmp}/craftcms-nginx-test.XXXXXXXX")
test_name=${test_directory##*/}
network=$test_name
nginx_container=$test_name-nginx
php_container=$test_name-php

# Called by the EXIT trap.
# shellcheck disable=SC2329
cleanup() {
    result=$?
    if (( result != 0 )); then
        docker logs "$nginx_container" >&2 || true
        docker logs "$php_container" >&2 || true
    fi
    docker rm -f "$nginx_container" "$php_container" >/dev/null 2>&1 || true
    docker network rm "$network" >/dev/null 2>&1 || true
    rm -rf "$test_directory"
    exit "$result"
}
trap 'cleanup' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -p "$test_directory/$document_root"
printf 'nginx smoke test: %s\n' "$flavor" > "$test_directory/$document_root/index.html"
# An empty PHP file must return HTTP 200 with an empty body through PHP-FPM.
touch "$test_directory/$document_root/probe.php"
chmod 755 "$test_directory" "$test_directory/$document_root"
chmod 644 "$test_directory/$document_root/"*

docker network create "$network" >/dev/null
docker run --detach --pull always --name "$php_container" \
    --network "$network" --network-alias php \
    --workdir /var/www \
    --mount "type=bind,source=$test_directory,target=/var/www,readonly" \
    "$php_image" >/dev/null

docker run --rm --network "$network" \
    --mount "type=bind,source=$test_directory,target=/var/www,readonly" \
    "$image" nginx -t

docker run --detach --name "$nginx_container" --network "$network" \
    --publish 127.0.0.1::80 \
    --mount "type=bind,source=$test_directory,target=/var/www,readonly" \
    "$image" >/dev/null
http_address=$(docker port "$nginx_container" 80/tcp)

check_http() {
    local static_body php_status
    static_body=$(curl --noproxy '*' --fail --silent --show-error --max-time 2 "http://$http_address/") || return 1
    [[ $static_body == "nginx smoke test: $flavor" ]] || return 1
    php_status=$(curl --noproxy '*' --fail --silent --show-error --max-time 2 \
        --output "$test_directory/php-response" --write-out '%{http_code}' \
        "http://$http_address/probe.php") || return 1
    [[ $php_status == 200 && ! -s $test_directory/php-response ]]
}

for ((attempt = 1; attempt <= 30; attempt++)); do
    if check_http; then
        echo "Passed: $image ($flavor), nginx -v, nginx -t, static HTTP and PHP-FPM HTTP"
        exit 0
    fi
    sleep 1
done

echo "HTTP checks failed for $image" >&2
exit 1
