#!/bin/bash
set -euo pipefail

# Script to complete the back-sync operation by pushing the merge commit to remote develop
# This script should be run by someone with write access to the repository

echo "========================================="
echo "Back-Sync Completion Script"
echo "========================================="
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Fetch latest changes
echo "Fetching latest changes from remote..."
git fetch --all

# Check if develop branch exists locally
if ! git rev-parse --verify develop > /dev/null 2>&1; then
    echo "Creating local develop branch from origin/develop..."
    git checkout -b develop origin/develop
else
    echo "Switching to develop branch..."
    git checkout develop
    echo "Pulling latest changes..."
    git pull origin develop
fi

# Check if main branch exists locally
if ! git rev-parse --verify main > /dev/null 2>&1; then
    echo "Creating local main branch from origin/main..."
    git fetch origin main:main
fi

# Check if back-sync merge is already done
MERGE_COMMIT=$(git log --oneline --grep="chore: sync develop with main after squash merge" -1 --format="%H" 2>/dev/null || echo "")

if [ -n "$MERGE_COMMIT" ]; then
    echo ""
    echo "✅ Back-sync merge commit already exists: $MERGE_COMMIT"
    echo ""
    
    # Check if it's already pushed
    if git branch -r --contains "$MERGE_COMMIT" | grep -q "origin/develop"; then
        echo "✅ Merge commit is already pushed to origin/develop"
        echo ""
        echo "Back-sync is complete!"
        exit 0
    else
        echo "⏳ Merge commit exists locally but needs to be pushed"
        echo ""
    fi
else
    echo ""
    echo "⚠️  No back-sync merge commit found. Creating it now..."
    echo ""
    
    # Perform the merge
    echo "Merging main into develop..."
    if git merge main --allow-unrelated-histories -m "chore: sync develop with main after squash merge"; then
        echo "✅ Merge completed successfully"
        MERGE_COMMIT=$(git rev-parse HEAD)
    else
        echo "❌ Merge failed. Please resolve conflicts and try again."
        exit 1
    fi
fi

echo ""
echo "Merge commit: $MERGE_COMMIT"
echo ""

# Show what will be pushed
echo "The following commit will be pushed to origin/develop:"
git log --oneline -1 "$MERGE_COMMIT"
echo ""

# Ask for confirmation
read -p "Do you want to push this to origin/develop? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Pushing to origin/develop..."
    if git push origin develop; then
        echo ""
        echo "========================================="
        echo "✅ Back-sync completed successfully!"
        echo "========================================="
        echo ""
        echo "The develop branch is now synchronized with main."
        echo "Merge commit $MERGE_COMMIT has been pushed to origin/develop."
    else
        echo ""
        echo "❌ Push failed. Please check your permissions and try again."
        exit 1
    fi
else
    echo ""
    echo "Push cancelled. The merge commit is ready but not pushed."
    echo "You can push it later with: git push origin develop"
fi
