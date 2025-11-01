#!/bin/bash

# Dynocards Build Script
# This script helps build and run the Dynocards iOS app

set -e  # Exit on any error

echo "🚀 Building Dynocards iOS App..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode command line tools not found. Please install Xcode."
    exit 1
fi

# Project configuration
PROJECT_NAME="Dynocards"
SCHEME_NAME="Dynocards"
WORKSPACE_PATH="Dynocards.xcworkspace"
PROJECT_PATH="Dynocards.xcodeproj"

# Default values
SIMULATOR="iPhone 15"
CONFIGURATION="Debug"
CLEAN=false
TEST=false
ARCHIVE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--simulator)
            SIMULATOR="$2"
            shift 2
            ;;
        -c|--configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --test)
            TEST=true
            shift
            ;;
        --archive)
            ARCHIVE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -s, --simulator SIMULATOR    Target simulator (default: iPhone 15)"
            echo "  -c, --configuration CONFIG   Build configuration (Debug/Release, default: Debug)"
            echo "  --clean                      Clean before building"
            echo "  --test                       Run tests"
            echo "  --archive                    Create archive build"
            echo "  -h, --help                   Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                          # Build for iPhone 15 simulator in Debug"
            echo "  $0 --clean --test           # Clean, build, and test"
            echo "  $0 -s 'iPhone 14' -c Release  # Build for iPhone 14 in Release"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_status "Starting build process..."
print_status "Simulator: $SIMULATOR"
print_status "Configuration: $CONFIGURATION"

# Determine if we should use workspace or project
BUILD_TARGET=""
if [ -d "$WORKSPACE_PATH" ]; then
    BUILD_TARGET="-workspace $WORKSPACE_PATH"
    print_status "Using workspace: $WORKSPACE_PATH"
elif [ -d "$PROJECT_PATH" ]; then
    BUILD_TARGET="-project $PROJECT_PATH"
    print_status "Using project: $PROJECT_PATH"
else
    print_error "No Xcode project or workspace found!"
    print_warning "Run this script from the project root directory."
    exit 1
fi

# Set destination
DESTINATION="platform=iOS Simulator,name=$SIMULATOR"

# Clean if requested
if [ "$CLEAN" = true ]; then
    print_status "Cleaning build artifacts..."
    xcodebuild clean $BUILD_TARGET -scheme $SCHEME_NAME -configuration $CONFIGURATION
    print_success "Clean completed"
fi

# Build the project
print_status "Building $PROJECT_NAME..."
if xcodebuild build $BUILD_TARGET \
    -scheme $SCHEME_NAME \
    -configuration $CONFIGURATION \
    -destination "$DESTINATION" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO; then
    print_success "Build completed successfully! ✅"
else
    print_error "Build failed! ❌"
    exit 1
fi

# Run tests if requested
if [ "$TEST" = true ]; then
    print_status "Running tests..."
    if xcodebuild test $BUILD_TARGET \
        -scheme $SCHEME_NAME \
        -configuration $CONFIGURATION \
        -destination "$DESTINATION" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO; then
        print_success "All tests passed! ✅"
    else
        print_error "Tests failed! ❌"
        exit 1
    fi
fi

# Create archive if requested
if [ "$ARCHIVE" = true ]; then
    print_status "Creating archive..."
    ARCHIVE_PATH="build/${PROJECT_NAME}-$(date +%Y%m%d-%H%M%S).xcarchive"
    
    if xcodebuild archive $BUILD_TARGET \
        -scheme $SCHEME_NAME \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH"; then
        print_success "Archive created: $ARCHIVE_PATH ✅"
    else
        print_error "Archive failed! ❌"
        exit 1
    fi
fi

print_success "🎉 All tasks completed successfully!"
print_status "You can now run the app in Xcode or use:"
print_status "open Dynocards.xcodeproj" 