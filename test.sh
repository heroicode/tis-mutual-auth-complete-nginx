#!/usr/bin/env sh
# shellcheck disable=SC2039  # local keyword is fine, actually
set -o errexit -o nounset -o noclobber
dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd); cd "$dir"
conf=${conf:-./conf}
in_docker=${in_docker:-false}
# root-only seems to not work when using an intermediate CA...
cafile=${cafile:-chain}

[ -e "$conf"/client.pem ] || { echo "Missing files. Run ./configure.sh" >&2; exit 3; }
[ -e ./.env ] && . ./.env

$in_docker || docker compose up --detach

test() {
    # shellcheck disable=SC3043
    local name="$1" result expected="$2"
    shift 2
    result=$(curl -sS "$@")
    echo "...$result..."
    [ "$expected" = "$result" ] || { echo "unexpected: '$result'"; return 1; }
    echo "$name passed" >&2
}

true && test no-client-cert '{"message":"Required SSL certificate not sent"}' \
    --cacert "$conf"/"$cafile".pem \
    `#--cert "$conf"/client.pem` \
    https://localhost:"${NGINX_HTTPS:-8448}"

true && test bad-client '{"message":"FAILED:self-signed certificate"}' \
    --cacert "$conf"/"$cafile".pem \
    --cert "$conf"/bad-client.pem \
    https://localhost:"${NGINX_HTTPS:-8448}"

test not-found '{"message":"Not Found"}' \
    --cacert "$conf"/"$cafile".pem \
    --cert "$conf"/client.pem \
    https://localhost:"${NGINX_HTTPS:-8448}"/admin

fingerprint=$(openssl x509 -noout -fingerprint -sha1 -in "$conf"/client.pem \
    | awk -F= '{ gsub(":","",$2); print tolower($2); }')

expected='{"dn":"CN=http client,OU=Local,O=Dev,L=Any,ST=ZZ,C=US","fingerprint":"'"$fingerprint"'","path":"/any"}'
# echo "$expected"
test good-any "$expected" \
    --cacert "$conf"/"$cafile".pem \
    --cert "$conf"/client.pem \
    https://localhost:"${NGINX_HTTPS:-8448}"/any

$in_docker || docker compose down
