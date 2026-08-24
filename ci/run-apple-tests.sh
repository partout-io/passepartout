#!/bin/bash
cd app-apple && scripts/bootstrap.sh && FOR_TESTING=1 swift test
