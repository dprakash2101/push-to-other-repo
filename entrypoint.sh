#!/bin/bash
set -e

echo "🔧 Starting Push-To-Other-Repo Action..."

#
# Validate Inputs
#
function fail() {
    echo "❌ ERROR: $1"
    exit 1
}

[ -z "$INPUT_SOURCE_DIRECTORY" ] && fail "Source directory is missing. Provide 'source_directory'."
[ -z "$INPUT_DESTINATION_REPOSITORY" ] && fail "Destination repository is missing. Provide 'destination_repository' in owner/repo format."
[ -z "$INPUT_TARGET_BRANCH" ] && fail "Target branch is missing. Provide 'target_branch'."
[ -z "$INPUT_USER_EMAIL" ] && fail "User email is missing. Provide 'user_email'."
[ -z "$INPUT_USER_NAME" ] && fail "User name is missing. Provide 'user_name'."
[ -z "$INPUT_API_TOKEN" ] && fail "GitHub token is missing. Provide 'api_token'."

if [[ ! -d "$INPUT_SOURCE_DIRECTORY" ]]; then
    fail "Source directory '$INPUT_SOURCE_DIRECTORY' does not exist. Check your repo path."
fi

echo "📁 Source Directory: $INPUT_SOURCE_DIRECTORY"
echo "📦 Destination Repo: $INPUT_DESTINATION_REPOSITORY"
echo "🌿 Target Branch: $INPUT_TARGET_BRANCH"

#
# Clone destination repo
#
DEST_DIR="/tmp/destination"
echo "⬇️ Cloning destination repository..."
if ! git clone --depth=1 --branch "$INPUT_TARGET_BRANCH" \
    "https://$INPUT_API_TOKEN@github.com/$INPUT_DESTINATION_REPOSITORY.git" \
    "$DEST_DIR"; then

    echo "⚠️ Could not clone branch '$INPUT_TARGET_BRANCH'. Trying fallback..."
    if ! git clone --depth=1 \
        "https://$INPUT_API_TOKEN@github.com/$INPUT_DESTINATION_REPOSITORY.git" \
        "$DEST_DIR"; then
        fail "Failed to clone destination repo. Verify repo name & permissions."
    fi

    cd "$DEST_DIR"
    echo "🌿 Creating branch '$INPUT_TARGET_BRANCH'..."
    git checkout -b "$INPUT_TARGET_BRANCH"
else
    cd "$DEST_DIR"
fi

#
# Git Identity
#
echo "👤 Configuring Git identity..."
git config user.email "$INPUT_USER_EMAIL"
git config user.name "$INPUT_USER_NAME"

#
# Sync Files
#
echo "🔄 Syncing files..."
rsync -av --delete \
    "$GITHUB_WORKSPACE/$INPUT_SOURCE_DIRECTORY/" \
    "$DEST_DIR/" \
    --exclude ".git"

#
# Check for changes
#
if git diff --quiet; then
    echo "✅ No changes detected. Nothing to commit."
    exit 0
fi

#
# Commit
#
echo "📝 Committing changes..."
git add .
if ! git commit -m "Sync from source repository"; then
    fail "Git commit failed. Possibly no staged changes or commit hooks blocked it."
fi

#
# Push with safe fast-forward
#
echo "🚀 Pushing to destination..."
if ! git push --ff-only origin "$INPUT_TARGET_BRANCH"; then
    echo "⚠️ Fast-forward push failed. Attempting safe pull + rebase..."

    if ! git pull --rebase origin "$INPUT_TARGET_BRANCH"; then
        fail "Auto-rebase failed. Manual conflict resolution required in destination repo."
    fi

    echo "🔁 Retrying push after rebase..."
    if ! git push origin "$INPUT_TARGET_BRANCH"; then
        fail "Push failed even after rebase. Check branch protection rules or permissions."
    fi
fi

echo "🎉 Sync complete!"
