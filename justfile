build:
    swift build

test:
    swift test

check:
    swift format lint --strict --recursive Sources Tests Package.swift
    swift build -Xswiftc -warnings-as-errors

gen-doc:
    swift package --allow-writing-to-directory docs generate-documentation --target IdentisureClient --disable-indexing --transform-for-static-hosting --hosting-base-path api-client-swift --output-path docs
    echo '<meta http-equiv="refresh" content="0; url=documentation/identisureclient/">' > docs/index.html
