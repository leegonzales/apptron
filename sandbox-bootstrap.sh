#!/bin/sh
# Apptron AI Sandbox Bootstrap Script
# Run this inside your Apptron project terminal to set up AI agent tools

set -e

echo "=== Apptron AI Sandbox Bootstrap ==="
echo "Setting up development tools for AI agent work..."
echo ""

# Update package index
echo "[1/7] Updating package index..."
apk update

# Core development tools
echo "[2/7] Installing core development tools..."
apk add git curl wget openssh-client bash

# Python environment (uv requires Python)
echo "[3/7] Installing Python..."
apk add python3 py3-pip

# Node.js and npm
echo "[4/7] Installing Node.js and npm..."
apk add nodejs npm

# Check Node version
NODE_VERSION=$(node --version 2>/dev/null || echo "not installed")
echo "    Node.js version: $NODE_VERSION"

# Try to install bun (may not work on 32-bit)
echo "[5/7] Attempting to install Bun..."
if curl -fsSL https://bun.sh/install | bash 2>/dev/null; then
    echo "    Bun installed successfully"
else
    echo "    Bun not available for this architecture (32-bit x86)"
fi

# Install uv for Python
echo "[6/7] Installing uv (Python package manager)..."
if pip3 install uv 2>/dev/null; then
    echo "    uv installed via pip"
elif curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null; then
    echo "    uv installed via installer"
else
    echo "    uv not available, using pip instead"
fi

# Try Claude Code npm install
echo "[7/7] Attempting Claude Code install..."
npm install -g @anthropic-ai/claude-code 2>/dev/null && echo "    Claude Code installed!" || echo "    Claude Code npm install failed (may need Node 18+)"

# Alternative: Try native installer
echo ""
echo "Trying Claude Code native installer..."
curl -fsSL https://claude.ai/install.sh 2>/dev/null | sh || echo "Native installer not available for 32-bit"

echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "Installed tools:"
echo "  - git: $(git --version 2>/dev/null || echo 'not found')"
echo "  - node: $(node --version 2>/dev/null || echo 'not found')"
echo "  - npm: $(npm --version 2>/dev/null || echo 'not found')"
echo "  - python: $(python3 --version 2>/dev/null || echo 'not found')"
echo "  - pip: $(pip3 --version 2>/dev/null || echo 'not found')"
echo ""

# Check for Claude Code
if command -v claude >/dev/null 2>&1; then
    echo "  - claude: $(claude --version 2>/dev/null || echo 'installed')"
else
    echo "  - claude: not available (32-bit architecture limitation)"
    echo ""
    echo "WORKAROUND: Run Claude Code on your Mac, connecting to this sandbox via git."
fi

echo ""
echo "=== Quick Start ==="
echo "1. Clone your project: git clone <repo-url>"
echo "2. Create API key env: export ANTHROPIC_API_KEY=your-key"
echo "3. Start coding!"
echo ""
echo "For multiple sandboxes: Create separate Apptron projects (one per repo)"
