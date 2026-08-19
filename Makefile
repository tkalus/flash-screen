SWIFT ?= swiftc
TARGET := flash-screen
SOURCE := flash-screen.swift

.PHONY: all build clean

all: build

build: $(TARGET)

$(TARGET): $(SOURCE)
	$(SWIFT) -framework AppKit -o $@ $<

clean:
	rm -f $(TARGET)
