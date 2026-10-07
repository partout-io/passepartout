#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${PARTOUT_SOURCE:=$HOME/passepartout/partout}"
: "${PARTOUT_LIB_DIR:=$HOME/.cache/partout-linux/partout/lib}"
: "${PARTOUT_OPENSSL_DIR:=$HOME/.cache/partout-linux/openssl/lib}"
: "${TUNNEL_OUTPUT:=/tmp/pp-tunnel-build}"
mkdir -p "$TUNNEL_OUTPUT"
cc -std=gnu11 -Wall -Wextra -Werror -fPIC -shared -pthread -I "$PARTOUT_SOURCE/src" tool/tunnel_helper/bridge.c -ldl -o "$TUNNEL_OUTPUT/libtunnel_bridge.so"
dart compile exe tool/tunnel_helper/main.dart -o "$TUNNEL_OUTPUT/partout-tunnel"
cp "$PARTOUT_LIB_DIR"/*.so "$TUNNEL_OUTPUT/"
cp "$PARTOUT_OPENSSL_DIR"/*.so* "$TUNNEL_OUTPUT/"
