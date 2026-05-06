#!/bin/sh

case "$1" in
    down)
        DIRECTION_FLAGS="-R"
        ;;
    up)
        DIRECTION_FLAGS=""
        ;;
    *)
        echo "Usage: $0 up|down" >&2
        exit 1
        ;;
esac

iperf3-darwin -c 10.12.0.1 -P 8 -t 600 $DIRECTION_FLAGS
