V := v
TARGET := autolt
BIN_DIR := bin

.PHONY: all build run clean

all: build

build:
	mkdir -p $(BIN_DIR)
	$(V) -prod -o $(BIN_DIR)/$(TARGET) .

run: build
	./$(BIN_DIR)/$(TARGET)

clean:
	rm -f $(BIN_DIR)/$(TARGET)
