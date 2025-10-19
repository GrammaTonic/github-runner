#!/bin/bash

# GitHub Wiki Population Script
# This script helps populate the GitHub wiki with documentation pages

echo "🚀 GitHub Wiki Population Guide"
echo "================================"
echo ""
echo "The wiki repository hasn't been initialized yet."
echo "To create and populate the wiki, follow these steps:"
echo ""
echo "1. Go to your repository: https://github.com/GrammaTonic/github-runner"
echo "2. Click on the 'Wiki' tab"
echo "3. Click 'Create the first page'"
echo "4. Copy and paste the content from: wiki-content/Home.md"
echo "5. Save the page"
echo ""
echo "After the wiki is initialized, run this script again to populate all pages:"
echo ""

# Function to create wiki pages
create_wiki_pages() {
	if [ ! -d "wiki-repo" ]; then
		echo "Cloning wiki repository..."
		git clone https://github.com/GrammaTonic/github-runner.wiki.git wiki-repo
		cd wiki-repo || exit 1
	else
		cd wiki-repo || exit 1
		git pull origin main
	fi

	echo "Copying wiki content..."

	# Copy all wiki pages
	for file in ../wiki-content/*.md; do
		if [ -f "$file" ]; then
			filename=$(basename "$file")
			echo "Creating page: $filename"
			cp "$file" "./$(basename "$filename" .md).md"
		fi
	done

	# Commit and push
	git add .
	git commit -m "docs: populate wiki with comprehensive documentation

- Add comprehensive home page with navigation
- Add detailed installation guide
- Add Docker configuration documentation  
- Add common issues and troubleshooting guide
- Include quick start links and external resources"

	git push origin main

	echo ""
	echo "✅ Wiki populated successfully!"
	echo "📖 View at: https://github.com/GrammaTonic/github-runner/wiki"
}

# Check if wiki exists
if curl -s -f -I "https://github.com/GrammaTonic/github-runner.wiki.git" >/dev/null 2>&1; then
	echo "Wiki repository exists. Populating pages..."
	create_wiki_pages
else
	echo "📝 Manual step required:"
	echo "   1. Visit: https://github.com/GrammaTonic/github-runner/wiki"
	echo "   2. Click 'Create the first page'"
	echo "   3. Use title: 'Home'"
	echo "   4. Copy content from: wiki-content/Home.md"
	echo "   5. Save the page"
	echo "   6. Run this script again: ./scripts/populate-wiki.sh"
fi

echo ""
echo "📋 Available wiki pages to create:"
echo "=================================="
for file in wiki-content/*.md; do
	if [ -f "$file" ]; then
		filename=$(basename "$file" .md)
		echo "  - $filename"
	fi
done

echo ""
echo "🔗 Quick setup command:"
echo "open https://github.com/GrammaTonic/github-runner/wiki"
