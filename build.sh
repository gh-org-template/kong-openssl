#!/usr/bin/env bash

set -eo pipefail

if [ -n "${DEBUG:-}" ]; then
    set -x
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export $(grep -v '^#' $SCRIPT_DIR/.env | xargs)

function main() {
    echo '--- installing openssl ---'
    mkdir -p /tmp/build
    with_backoff curl --fail -sSLo openssl.tar.gz "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
    tar -xzvf openssl.tar.gz
    pushd openssl-${OPENSSL_VERSION}

        # Determine the architecture and set the appropriate OpenSSL target
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            OPENSSL_TARGET="linux-x86_64"
        elif [ "$ARCH" = "aarch64" ]; then
            OPENSSL_TARGET="linux-aarch64"
        else
            echo "Unsupported architecture: $ARCH"
            exit 1
        fi

        # Configure for static build without mixing flags
        ./Configure \
            no-shared \
            no-dso \
            no-unit-test \
            $OPENSSL_TARGET \
            -fPIC \
            --prefix=/usr/local/kong \
            --openssldir=/usr/local/kong

        make -j$(nproc)
        make install_sw DESTDIR=/tmp/build
    popd
    echo '--- installed openssl ---'
}


# Retries a command a configurable number of times with backoff.
#
# The retry count is given by ATTEMPTS (default 5), the initial backoff
# timeout is given by TIMEOUT in seconds (default 1.)
#
# Successive backoffs double the timeout.
function with_backoff {
    local max_attempts=${ATTEMPTS-5}
    local timeout=${TIMEOUT-5}
    local attempt=1
    local exitCode=0

    while (( $attempt < $max_attempts ))
    do
        if "$@"
        then
            return 0
        else
            exitCode=$?
        fi

        echo "Failure! Retrying in $timeout.." 1>&2
        sleep $timeout
        attempt=$(( attempt + 1 ))
        timeout=$(( timeout * 2 ))
    done

    if [[ $exitCode != 0 ]]
    then
        echo "You've failed me for the last time! ($@)" 1>&2
    fi

    return $exitCode
}

main
