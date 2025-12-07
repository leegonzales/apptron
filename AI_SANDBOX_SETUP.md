# AI Agent Sandbox Setup Guide

## Current Status (Updated)

### What Works

| Tool | Status | Notes |
|------|--------|-------|
| git | ✅ Works | `apk add git` |
| python3 | ✅ Works | `apk add python3 py3-pip` |
| node/npm | ✅ Works | Node 24 available via `apk add nodejs npm` |
| pip packages | ✅ Works | Most pure Python packages |
| npm packages | ✅ Works | Pure JS packages |
| make | ✅ Works | Pre-installed |
| curl/wget | ✅ Works | Full network access |
| go | ✅ Works | `source /etc/goprofile` |
| **claude-code** | ⚠️ Installs, OAuth blocked | See below |
| gemini-cli | ❌ Native binary | 64-bit only |
| bun | ❌ Native binary | 64-bit only |

### Claude Code Status

**Good news:** Claude Code npm package installs and runs! Node 24 is available in Alpine x86.

```sh
apk add nodejs npm
npm install -g @anthropic-ai/claude-code
claude  # This works!
```

**The blocker:** OAuth login requires a browser redirect, which doesn't work in Apptron's browser-in-browser environment.

### Authentication Options

| Method | Works in Apptron? | Notes |
|--------|-------------------|-------|
| OAuth (Pro/Max subscription) | ❌ No | Browser redirect fails |
| API Key (`ANTHROPIC_API_KEY`) | ✅ Yes | Separate billing from subscription |

**If you have a Pro subscription:** The OAuth token is stored in macOS Keychain and is not portable to Apptron. You would need a separate API key for sandbox work.

## Recommended Approaches

### For API Key Users

If you're using API key billing (not Pro subscription):

```sh
# In Apptron terminal
apk add nodejs npm git python3
npm install -g @anthropic-ai/claude-code

export ANTHROPIC_API_KEY=sk-ant-xxxxx
claude
```

This works fully inside Apptron.

### For Pro Subscription Users

**Apptron is not ideal for Claude Code with Pro subscriptions** due to OAuth limitations.

Better alternatives:

1. **Docker sandbox on Mac**: Run Claude Code on Mac with Pro auth, mount a Docker container's filesystem
2. **Git reset safety net**: Run Claude Code in YOLO mode on Mac inside a git repo - use `git reset --hard` to undo damage
3. **Separate API key**: Get an API key for sandbox experiments (separate billing)

### Using Anthropic API Directly (Alternative)

If Claude Code OAuth doesn't work, use the API directly:

```sh
# In Apptron
apk add python3 py3-pip
pip install anthropic

python3 << 'EOF'
import anthropic
import os

# Set your API key
os.environ["ANTHROPIC_API_KEY"] = "sk-ant-xxxxx"

client = anthropic.Anthropic()
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello from Apptron!"}]
)
print(response.content[0].text)
EOF
```

## Quick Setup (API Key Users)

```sh
# One-liner setup in Apptron terminal
apk add nodejs npm git python3 py3-pip curl && \
npm install -g @anthropic-ai/claude-code && \
echo 'export ANTHROPIC_API_KEY=your-key-here' >> ~/.profile && \
source ~/.profile && \
claude
```

## What Apptron IS Good For

Even without full Claude Code integration, Apptron provides:

- **Isolated Linux environment** for experiments
- **Full network access** for package installation
- **Persistent project storage** synced to cloud
- **No-install browser access** - share URLs with others
- **Safe experimentation** - reload page to reset

## Future Improvements Needed

For full AI agent sandbox support, Apptron would need:

1. **64-bit support** - Replace v86 with QEMU-Wasm (see UPGRADE_PROPOSAL.md)
2. **OAuth relay** - Mechanism to complete OAuth flow via parent browser
3. **Credential bridge** - Way to pass Mac Keychain tokens to sandbox

See `UPGRADE_PROPOSAL.md` for technical paths to these improvements.
