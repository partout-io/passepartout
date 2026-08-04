#!/bin/bash
expected="let forPreviews = false"
grep "^$expected" partout/Package.swift
