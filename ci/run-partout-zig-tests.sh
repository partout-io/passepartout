#!/bin/bash
cd partout/zig
zig build test -Dembed-c=true
