default:
    @just --list

start:
    go run .

build:
    go build -o fresh .

clean:
    go clean ./...
    rm -rf tmp fresh main

test:
    go test ./...

format:
    go fmt ./...

alias fmt := format
