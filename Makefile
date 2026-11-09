.PHONY: all build test app run clean xcode

all: test app

test:
	swift test

build:
	swift build

app:
	./scripts/bundle_app.sh release

debug-app:
	./scripts/bundle_app.sh debug

run: app
	open build/MoriKey.app

clean:
	rm -rf .build build

xcode:
	xed .
