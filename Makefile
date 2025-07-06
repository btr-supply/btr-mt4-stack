# MetaTrader 4 Redis DLL Build System with MITCH Protocol Support

.DEFAULT_GOAL := help

# Variables
RUST_DIR = rust_dlls
DLL_NAME = redis_client.dll
TARGET = i686-pc-windows-gnu

# Build the release DLL
.PHONY: build
build:
	@echo "Building release DLL..."
	@cd $(RUST_DIR) && cargo build --release --target $(TARGET)

# Build the test runner (release mode for Wine32 compatibility)
.PHONY: build-test
build-test:
	@echo "Building test runner..."
	@cd $(RUST_DIR) && cargo build --bin test_runner --release --target $(TARGET)

# Deploy the release DLL
.PHONY: deploy
deploy: build
	@echo "Deploying DLL..."
	@cp $(RUST_DIR)/target/$(TARGET)/release/$(DLL_NAME) Libraries/$(DLL_NAME)

# Run DLL tests
.PHONY: test
test: deploy build-test
	@echo "Running DLL tests with Wine..."
	@cd $(RUST_DIR) && wine target/$(TARGET)/release/test_runner.exe

# Compile MQL4 scripts and headers
.PHONY: compile-mql4
compile-mql4:
	@echo "Compiling MQL4 scripts and headers..."
	@wine ../terminal.exe /portable /compile:Scripts/BTRRedisTest.mq4
	@wine ../terminal.exe /portable /compile:Scripts/BTRMitchTest.mq4
	@wine ../terminal.exe /portable /compile:Include/BTRRedisClient.mqh
	@wine ../terminal.exe /portable /compile:Include/BTRMitchModel.mqh
	@wine ../terminal.exe /portable /compile:Include/BTRMitchSerializer.mqh

# Run MITCH serialization tests
.PHONY: test-mitch
test-mitch: compile-mql4
	@echo "Running MITCH serialization tests..."
	@wine ../terminal.exe /portable /script:Scripts/BTRMitchTest.mq4

# Run Redis integration tests
.PHONY: test-redis
test-redis: compile-mql4
	@echo "Running Redis integration tests..."
	@wine ../terminal.exe /portable /script:Scripts/BTRRedisTest.mq4

# Run all tests (DLL + MQL4 + MITCH + Redis)
.PHONY: test-all
test-all: test test-mitch test-redis
	@echo "All tests completed!"

# Performance benchmark for MITCH serialization
.PHONY: benchmark-mitch
benchmark-mitch: compile-mql4
	@echo "Running MITCH performance benchmarks..."
	@wine ../terminal.exe /portable /script:Scripts/BTRMitchTest.mq4

# Clean all build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@cd $(RUST_DIR) && cargo clean
	@rm -f Libraries/$(DLL_NAME)
	@rm -f Scripts/*.ex4
	@rm -f Include/*.log

# Full development workflow with MITCH support
.PHONY: dev
dev: deploy test compile-mql4 test-mitch

# Full development workflow with all tests
.PHONY: dev-full
dev-full: deploy test compile-mql4 test-all

# Create a production release with MITCH support
.PHONY: release
release: deploy compile-mql4
	@echo "Production release ready with MITCH support!"

# Validate MITCH protocol implementation
.PHONY: validate-mitch
validate-mitch: compile-mql4
	@echo "Validating MITCH protocol implementation..."
	@wine ../terminal.exe /portable /script:Scripts/BTRMitchTest.mq4
	@echo "MITCH validation completed!"

# Quick syntax check for all MQL4 files
.PHONY: check-syntax
check-syntax:
	@echo "Checking MQL4 syntax..."
	@wine ../terminal.exe /portable /compile:Include/BTRMitchModel.mqh
	@wine ../terminal.exe /portable /compile:Include/BTRMitchSerializer.mqh
	@wine ../terminal.exe /portable /compile:Include/BTRRedisClient.mqh
	@wine ../terminal.exe /portable /compile:Scripts/BTRMitchTest.mq4
	@wine ../terminal.exe /portable /compile:Scripts/BTRRedisTest.mq4
	@echo "Syntax check completed!"

# Show help
.PHONY: help
help:
	@echo "Available Commands:"
	@echo "  make build          - Build the release DLL"
	@echo "  make deploy         - Deploy the DLL to Libraries/"
	@echo "  make test           - Run the Wine32-based DLL tests"
	@echo "  make compile-mql4   - Compile all MQL4 scripts and headers"
	@echo "  make test-mitch     - Run MITCH serialization tests"
	@echo "  make test-redis     - Run Redis integration tests"
	@echo "  make test-all       - Run all tests (DLL + MQL4 + MITCH + Redis)"
	@echo "  make benchmark-mitch - Run MITCH performance benchmarks"
	@echo "  make dev            - Run development workflow with MITCH"
	@echo "  make dev-full       - Run full development workflow with all tests"
	@echo "  make release        - Create production release with MITCH support"
	@echo "  make validate-mitch - Validate MITCH protocol implementation"
	@echo "  make check-syntax   - Quick syntax check for all MQL4 files"
	@echo "  make clean          - Remove all build artifacts"
	@echo "  make help           - Show this help message" 