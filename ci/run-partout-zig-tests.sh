#!/bin/bash
cd partout/zig
zig build test -Dopenvpn=true -Dwireguard=true
