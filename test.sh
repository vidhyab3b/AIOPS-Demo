#!/bin/bash

# Usage:
# ./git_add_file.sh <git_repo_url> <file_to_add> [commit_message]

# Exit on error
set -e

# Input validation
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <git_repo_url> <file_to_add> [commit_message]"
  exit 1
fi

REPO_URL="$1"
FILE_TO_ADD="$2"
COMMIT_MSG=${3:-"Add $FILE_TO_ADD"}
WORK_DIR="temp_git_repo_$$"

# Clone repo
echo "Cloning repository..."
git clone "$REPO_URL" "$WORK_DIR"
cd "$WORK_DIR"

# Copy file into the repo (assumes the file is outside the repo)
cp "../$FILE_TO_ADD" .

# Add and commit the file
echo "Adding and committing $FILE_TO_ADD..."
git add "$FILE_TO_ADD"
git commit -m "$COMMIT_MSG"

# Push the changes
echo "Pushing to remote..."
git push

echo "Done. File '$FILE_TO_ADD' has been added and pushed to $REPO_URL."

# Cleanup
cd ..
rm -rf "$WORK_DIR"

