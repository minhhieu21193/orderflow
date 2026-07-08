.PHONY: run build test tidy

# Start the API locally (defaults to :8080).
run:
	go run ./cmd/api

# Compile the api binary into ./bin.
build:
	go build -o bin/api ./cmd/api

test:
	go test ./...

tidy:
	go mod tidy
