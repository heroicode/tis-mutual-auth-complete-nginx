# set dotenv-load
set ignore-comments

# default build action (test)
@build:
    ./test.sh

# run tests (default)
@test: build

[private]
@showcerts:
    openssl s_client -showcerts -state \
    -servername "localhost:${NGINX_HTTPS:-8448}" \
    -connect "localhost:${NGINX_HTTPS:-8448}" \
    -CAfile ./conf/root.pem \
    -cert ./conf/client.pem

# generate certificates
@configure:
    ./configure.sh

# remove certificates
@clean:
    docker compose down
    find conf -maxdepth 1 -name '*.pem' -exec sh -c 'echo deleting {}; rm {}' \;

# list commands we depend on
@depends:
    command -v openssl
    command -v docker
    command -v curl
