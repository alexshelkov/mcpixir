#!/bin/bash
# Simple release script for Mcpixir

set -e

# Check if we have a version argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 VERSION"
  echo "Example: $0 0.2.0"
  exit 1
fi

VERSION=$1

# Validate version format
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid version format. Please use MAJOR.MINOR.PATCH"
  exit 1
fi

# Check if git repo is clean
if [[ -n $(git status --porcelain) ]]; then
  echo "Git working directory is not clean. Please commit or stash your changes before releasing."
  exit 1
fi

echo "Starting release process for v$VERSION..."

# Run release mix task
mix mcp.release $VERSION

# Push changes and tag
echo "Pushing changes and tag to remote..."
git push --follow-tags

echo "Release v$VERSION completed!"
echo "The package should now be available on Hex.pm"