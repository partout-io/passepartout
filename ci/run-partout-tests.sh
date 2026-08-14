#!/bin/bash
cd partout
zig build test -Dopenvpn=true -Dwireguard=true
