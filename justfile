build:
    swift build

test:
    swift test

check:
    swift format lint --strict --recursive Sources Tests Package.swift
    swift build -Xswiftc -warnings-as-errors
