#!/usr/bin/env bash

# setup-github-auth.sh
# Helper script to streamline GitHub authentication for Compose for Agents demos

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 GitHub Authentication Setup for Compose for Agents${NC}"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed.${NC}"
    echo ""
    echo "Please install it from: https://cli.github.com/"
    echo ""
    echo "Installation instructions:"
    echo "  - macOS: brew install gh"
    echo "  - Linux: See https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    echo "  - Windows: See https://github.com/cli/cli#installation"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI found: $(gh --version | head -n1)${NC}"
echo ""

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  You are not authenticated with GitHub.${NC}"
    echo ""
    echo "Starting GitHub authentication process..."
    echo ""
    
    # Run gh auth login
    gh auth login
    
    echo ""
fi

# Verify authentication worked
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Authentication failed. Please try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Successfully authenticated with GitHub${NC}"
echo ""

# Get the token
echo "Retrieving GitHub token..."
TOKEN=$(gh auth token)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ Failed to retrieve GitHub token${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Token retrieved successfully${NC}"
echo ""

# List of directories that need .mcp.env files
DIRS_WITH_MCP=("agno" "adk-sock-shop")

echo "Setting up .mcp.env files..."
echo ""

for dir in "${DIRS_WITH_MCP[@]}"; do
    if [ -d "$dir" ]; then
        MCP_FILE="$dir/.mcp.env"
        
        # Create or update the .mcp.env file
        if [ -f "$MCP_FILE" ]; then
            # File exists, check if it already has the token
            if grep -q "^github.personal_access_token=" "$MCP_FILE"; then
                # Update existing token
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS sed
                    sed -i '' "s|^github.personal_access_token=.*|github.personal_access_token=$TOKEN|" "$MCP_FILE"
                else
                    # Linux sed
                    sed -i "s|^github.personal_access_token=.*|github.personal_access_token=$TOKEN|" "$MCP_FILE"
                fi
                echo -e "  ${GREEN}✅ Updated token in $MCP_FILE${NC}"
            else
                # Append token to existing file
                echo "github.personal_access_token=$TOKEN" >> "$MCP_FILE"
                echo -e "  ${GREEN}✅ Added token to $MCP_FILE${NC}"
            fi
        else
            # Create new file
            echo "github.personal_access_token=$TOKEN" > "$MCP_FILE"
            echo -e "  ${GREEN}✅ Created $MCP_FILE with token${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠️  Directory $dir not found, skipping${NC}"
    fi
done

echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "Your GitHub token has been configured in the following locations:"
for dir in "${DIRS_WITH_MCP[@]}"; do
    if [ -d "$dir" ]; then
        echo "  - $dir/.mcp.env"
    fi
done
echo ""
echo "You can now run the demos that require GitHub access:"
echo "  cd agno && docker compose up --build"
echo ""
