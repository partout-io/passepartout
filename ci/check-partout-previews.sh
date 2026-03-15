#!/bin/bash
expected="let forPreviews = false"
grep "^$expected" app-cross/partout/Package.swift
