#!/bin/bash
# Verification script to check if back-sync was successful

echo "========================================"
echo "Back-Sync Verification"
echo "========================================"
echo ""

# Check if develop branch exists locally
if git rev-parse --verify develop > /dev/null 2>&1; then
    echo "✅ Local develop branch exists"
    
    # Check for the back-sync merge commit
    MERGE_COMMIT=$(git log develop --oneline --grep="chore: sync develop with main after squash merge" -1 --format="%H" 2>/dev/null || echo "")
    
    if [ -n "$MERGE_COMMIT" ]; then
        echo "✅ Back-sync merge commit found: $MERGE_COMMIT"
        echo ""
        echo "Commit details:"
        git log --oneline -1 "$MERGE_COMMIT"
        echo ""
        
        # Show the changes
        echo "Files changed in merge:"
        git show --stat "$MERGE_COMMIT"
        echo ""
        
        # Check if pushed to remote
        if git ls-remote --heads origin develop > /dev/null 2>&1; then
            if git branch -r --contains "$MERGE_COMMIT" 2>/dev/null | grep -q "origin/develop"; then
                echo "✅ Merge commit is pushed to origin/develop"
                echo ""
                echo "🎉 Back-sync is COMPLETE!"
            else
                echo "⏳ Merge commit exists locally but NOT pushed to origin/develop"
                echo ""
                echo "Next step: Run ./complete-back-sync.sh to push to remote"
            fi
        fi
    else
        echo "❌ No back-sync merge commit found on develop branch"
        echo ""
        echo "Run ./complete-back-sync.sh to perform the back-sync"
    fi
else
    echo "❌ Local develop branch does not exist"
    echo "Run: git fetch origin develop:develop"
fi

echo ""
echo "========================================"
