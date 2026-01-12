#!/bin/bash

# Coverage script for KYA Protocol
# Generates coverage report and checks thresholds

set -e

echo "==========================================="
echo "KYA Protocol Coverage Report"
echo "==========================================="

# Run tests with coverage
echo "Running tests with coverage..."
forge coverage --report lcov

# Generate HTML report (if lcov installed)
if command -v genhtml &> /dev/null; then
    echo "Generating HTML coverage report..."
    genhtml coverage.lcov -o coverage-report
    echo "HTML report generated in coverage-report/"
fi

# Check coverage thresholds
echo ""
echo "Checking coverage thresholds..."

# Extract coverage percentage from forge coverage output
COVERAGE=$(forge coverage --report summary 2>/dev/null | grep -oP '\d+\.\d+%' | head -1 | sed 's/%//' || echo "0")

if [ -z "$COVERAGE" ]; then
    echo "Warning: Could not extract coverage percentage"
    COVERAGE=0
fi

echo "Current coverage: ${COVERAGE}%"
echo "Target coverage: 90%"

# Check if coverage meets threshold
if (( $(echo "$COVERAGE < 90" | bc -l) )); then
    echo "ERROR: Coverage ${COVERAGE}% is below 90% threshold"
    exit 1
else
    echo "SUCCESS: Coverage ${COVERAGE}% meets 90% threshold"
fi

echo "==========================================="
echo "Coverage check complete"
echo "==========================================="

