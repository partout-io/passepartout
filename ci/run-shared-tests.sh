#!/bin/bash
pushd submodules/partout
git submodule init vendors/swon
git submodule update --depth 1 vendors/swon
popd
cd app-shared && swift test
