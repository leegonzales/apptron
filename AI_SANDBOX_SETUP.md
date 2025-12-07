# AI Agent Sandbox Setup Guide

## The Challenge

Apptron runs **32-bit x86 Alpine Linux** via emulation. Modern AI CLI tools (Claude Code, Gemini CLI, Codex) are compiled for x86_64 only. This means they won't run natively inside the sandbox.

## Solution: Hybrid Architecture

Run AI agents on your Mac, but have them execute commands inside the Apptron sandbox via SSH.

```
┌──────────────────────────────┐     ┌──────────────────────────────┐
│          YOUR MAC            │     │    APPTRON SANDBOX           │
│  ┌────────────────────────┐  │     │  ┌────────────────────────┐  │
│  │   Claude Code (YOLO)   │  │ SSH │  │   Alpine Linux (x86)   │  │
│  │   Gemini CLI           │──┼─────┼──│   - git, python, node  │  │
│  │   Codex                │  │     │  │   - your project code  │  │
│  └────────────────────────┘  │     │  │   - isolated filesystem │  │
│                              │     │  └────────────────────────┘  │
└──────────────────────────────┘     └──────────────────────────────┘
```

## Quick Setup

### Step 1: Bootstrap the Sandbox

Inside your Apptron project terminal, run:

```sh
# Download and run bootstrap script
curl -O https://raw.githubusercontent.com/leegonzales/apptron/main/sandbox-bootstrap.sh
chmod +x sandbox-bootstrap.sh
./sandbox-bootstrap.sh
```

Or manually:
```sh
apk update
apk add git curl python3 py3-pip nodejs npm openssh dropbear
```

### Step 2: Set Up SSH Access

Inside Apptron:
```sh
# Install dropbear (lightweight SSH server)
apk add dropbear

# Generate host keys
dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key

# Create your user (use your Mac username for convenience)
adduser -D yourname
echo "yourname:sandbox123" | chpasswd

# Start SSH server on port 22
dropbear -p 22 -E -F &

# Note your session IP (shown in terminal prompt or run:)
hostname -i
```

### Step 3: Get Your Public URL

Apptron creates a public URL for any port you expose. Look for something like:
```
tcp-22-c0a87fxx-localdev.apptron.dev
```

Or construct it:
- Port: 22
- IP: Convert your session IP (192.168.127.xx) to hex
- Pattern: `tcp-{port}-{hex-ip}-{user}.apptron.dev`

### Step 4: Connect AI Agents

On your Mac, configure Claude Code to use the sandbox:

```sh
# Test SSH connection first
ssh yourname@tcp-22-c0a87fxx-localdev.apptron.dev

# Run Claude Code with SSH remote
claude --remote ssh://yourname@tcp-22-c0a87fxx-localdev.apptron.dev
```

Or configure in `.claude/settings.json`:
```json
{
  "remote": {
    "host": "tcp-22-c0a87fxx-localdev.apptron.dev",
    "user": "yourname"
  }
}
```

## Multiple Sandboxes (One Per Project)

1. Create a new Apptron project for each repo
2. Each gets its own isolated filesystem
3. Each can have its own SSH server on port 22
4. Each gets a unique public URL

```
Project: my-api        → tcp-22-abc123-localdev.apptron.dev
Project: my-frontend   → tcp-22-def456-localdev.apptron.dev
Project: experiments   → tcp-22-ghi789-localdev.apptron.dev
```

## YOLO Mode Configuration

For maximum AI agent freedom, configure Claude Code:

```sh
# On your Mac - run against the sandbox
claude --dangerously-skip-permissions --remote ssh://user@sandbox-url
```

The AI can now:
- Run any command in the sandbox
- Modify any file
- Install packages
- Run servers
- **Cannot damage your Mac** - everything is isolated!

## What Works Inside the Sandbox

| Tool | Status | Notes |
|------|--------|-------|
| git | ✅ Works | `apk add git` |
| python3 | ✅ Works | `apk add python3 py3-pip` |
| node/npm | ✅ Works | `apk add nodejs npm` |
| pip packages | ✅ Works | Most pure Python packages |
| npm packages | ✅ Works | Pure JS packages |
| make | ✅ Works | Pre-installed |
| curl/wget | ✅ Works | Full network access |
| go | ✅ Works | `source /etc/goprofile` |
| bun | ❌ 64-bit only | Use npm instead |
| uv | ⚠️ Maybe | Try `pip install uv` |
| claude-code | ❌ 64-bit only | Run on Mac, SSH into sandbox |
| gemini-cli | ❌ 64-bit only | Run on Mac, SSH into sandbox |

## Alternative: Git-Based Workflow

If SSH is problematic, use a git-based approach:

1. Create a GitHub repo for your project
2. Clone it into both your Mac AND the Apptron sandbox
3. Run AI agents on Mac against local clone
4. When AI makes changes, push to GitHub
5. Pull changes in Apptron sandbox to test

```sh
# On Mac - AI works here
claude "refactor the authentication module"
git push

# In Apptron - test here
git pull
npm test
```

## Persistence Notes

- **Persisted**: `/home`, `/project`, `/public` directories
- **Reset on reload**: System directories, installed packages

To persist your SSH setup, add to your project's init script:
```sh
# Save this as ~/init.sh and it will run on project load
apk add dropbear
dropbear -p 22 -E &
```

## Security Notes

- The sandbox is isolated from your Mac
- Network is virtual (192.168.127.0/24)
- Files can't escape to your Mac filesystem
- Worst case: reload the page to reset everything
- API keys in the sandbox stay in the sandbox

## Troubleshooting

**Can't connect via SSH?**
- Check the sandbox is running (browser tab open)
- Verify the public URL format
- Try: `curl -v https://tcp-22-xxx.apptron.dev` to test

**Packages not persisting?**
- Add install commands to `~/init.sh`
- Or use the project filesystem for state

**AI agent timeouts?**
- v86 emulation is slower than native
- Increase timeout settings in your AI agent config
