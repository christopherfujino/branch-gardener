SRCS=$(wildcard *.dart)
BUILD_DIR=build

main: $(SRCS) $(BUILD_DIR)
	dart compile exe bin/branch_gardener.dart -o build/bgard

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
