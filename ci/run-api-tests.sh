#!/bin/bash
set -e
cd api
npm ci
npm test
