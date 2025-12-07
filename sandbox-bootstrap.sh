#!/bin/sh
# Apptron AI Sandbox Bootstrap Script
# Run this inside your Apptron project terminal to set up development tools

set -e

echo "=== Apptron AI Sandbox Bootstrap ==="
echo "Setting up development tools..."
echo ""

# Update package index
echo "[1/6] Updating package index..."
apk update

# Core development tools
echo "[2/6] Installing core development tools..."
apk add git curl wget bash zsh

# Python environment
echo "[3/6] Installing Python..."
apk add python3 py3-pip

# Node.js and npm (Node 24 available!)
echo "[4/6] Installing Node.js and npm..."
apk add nodejs npm

# Check Node version
NODE_VERSION=$(node --version 2>/dev/null || echo "not installed")
echo "    Node.js version: $NODE_VERSION"

# Install Claude Code
echo "[5/6] Installing Claude Code..."
if npm install -g @anthropic-ai/claude-code 2>/dev/null; then
    echo "    Claude Code installed successfully!"
else
    echo "    Claude Code installation failed"
fi

# Python AI packages
echo "[6/6] Installing Python AI packages..."
pip3 install anthropic google-generativeai openai 2>/dev/null || echo "    Some Python packages failed"

echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "Installed tools:"
echo "  - git: $(git --version 2>/dev/null || echo 'not found')"
echo "  - node: $(node --version 2>/dev/null || echo 'not found')"
echo "  - npm: $(npm --version 2>/dev/null || echo 'not found')"
echo "  - python: $(python3 --version 2>/dev/null || echo 'not found')"
echo ""

# Check for Claude Code
if command -v claude >/dev/null 2>&1; then
    echo "  - claude: installed"
    echo ""
    echo "=== Claude Code Authentication ==="
    echo ""
    echo "Claude Code is installed! However:"
    echo ""
    echo "  OAuth (Pro/Max subscription): Does NOT work in Apptron"
    echo "    - Browser redirect can't complete in nested browser"
    echo ""
    echo "  API Key: WORKS in Apptron"
    echo "    - Set: export ANTHROPIC_API_KEY=sk-ant-xxxxx"
    echo "    - Then run: claude"
    echo ""
else
    echo "  - claude: not installed"
fi

echo ""
echo "=== Quick Start ==="
echo "1. Set API key: export ANTHROPIC_API_KEY=your-key"
echo "2. Run claude: claude"
echo ""
echo "For Pro subscription users: See AI_SANDBOX_SETUP.md for alternatives"
