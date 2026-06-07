#!/bin/sh
case "$1" in
    down)
        DIRECTION_FLAGS="-R"
        ;;
    up)
        DIRECTION_FLAGS=""
        ;;
    *)
        echo "Usage: $0 up|down udp|tcp" >&2
        exit 1
        ;;
esac
case "$2" in
    udp)
        ADDR=10.12.0.1
        ;;
    tcp)
        ADDR=10.13.0.1
        ;;
    *)
        echo "Usage: $0 up|down udp|tcp" >&2
        exit 1
        ;;
esac
iperf3-darwin -c $ADDR -P 8 -t 600 $DIRECTION_FLAGS
