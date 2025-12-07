# Apptron Upgrade Proposal: AI Agent Sandbox Optimizations

## Current Limitations

| Issue | Current State | Impact |
|-------|---------------|--------|
| 32-bit only | v86 emulates x86 (32-bit) | Many modern tools won't run |
| Slow emulation | JIT but still interpreted | Commands take seconds |
| Basic shell | BusyBox ash | Limited features |
| Package reset | apk installs lost on reload | Setup time every session |

## Proposed Upgrades

### Option A: Replace v86 with QEMU-Wasm (Recommended)

**What:** Swap v86 for [QEMU-Wasm](https://github.com/ktock/qemu-wasm), which supports **x86_64** in the browser.

**Effort:** Medium-High (significant changes to boot.go and Wanix integration)

**Benefits:**
- Full 64-bit x86_64 support
- Run Claude Code, Gemini CLI, Bun, modern tools natively
- Active development with FOSDEM 2025 presentation
- JIT compilation for better performance

**Technical Path:**
```
Current:    Browser → Wanix → v86 (32-bit) → Alpine Linux
Proposed:   Browser → Wanix → QEMU-Wasm (64-bit) → Alpine/Debian Linux
```

**Key Files to Modify:**
- `boot.go` - Replace v86 initialization with QEMU-Wasm
- Wanix integration layer - May need updates for new emulator interface
- Build system - New QEMU-Wasm bundle instead of v86

**Demo:** https://ktock.github.io/qemu-wasm-demo/

---

### Option B: container2wasm Integration

**What:** Use [container2wasm](https://github.com/ktock/container2wasm) to run pre-built x86_64 Docker images in browser.

**Effort:** Medium

**Benefits:**
- Run any Docker image in browser
- Pre-configure containers with all tools installed
- x86_64 support via Bochs emulator
- Simpler than full QEMU integration

**Approach:**
1. Build a Docker image with all AI tools pre-installed:
   ```dockerfile
   FROM alpine:latest
   RUN apk add nodejs npm git python3 zsh tmux
   RUN npm install -g @anthropic-ai/claude-code
   # etc.
   ```
2. Convert to WASM: `c2w your-image:latest output.wasm`
3. Load WASM in Apptron instead of v86

**Limitations:**
- Networking requires WebSocket bridge (Apptron already has this!)
- Larger bundle sizes
- Bochs is slower than v86's JIT

---

### Option C: Hybrid Architecture

**What:** Keep v86 for lightweight tasks, add QEMU-Wasm for heavy workloads.

**Effort:** High

**Benefits:**
- Fast boot for simple projects (v86)
- Full capability for AI agent work (QEMU-Wasm)
- User chooses based on needs

**Implementation:**
- Project creation offers "Light (32-bit)" vs "Full (64-bit)" option
- Different VM bundles loaded based on choice

---

### Option D: Quick Wins (No Emulator Change)

If replacing the emulator is too much work, these improvements help within current constraints:

#### D1. Better Shell
```sh
# Add to sandbox-bootstrap.sh
apk add zsh zsh-autosuggestions zsh-syntax-highlighting
apk add tmux
chsh -s /bin/zsh
```

#### D2. Persistent Package Layer
Modify Apptron to save installed packages to cloud storage:
```
/persistent/apk-cache/  → synced to R2
/persistent/node_modules/ → synced to R2
```

**Files to modify:**
- `worker/src/r2fs.ts` - Add package cache sync
- `boot.go` - Mount persistent package dirs

#### D3. Pre-built "AI Agent" Environment Bundle
Create a custom Alpine bundle with tools pre-installed:
- Modify `Makefile` bundle targets
- Pre-install: nodejs, npm, git, python3, zsh, tmux
- Pre-install npm packages: claude-code (if it works)
- Compress into `bundles/ai-agent.tar.gz`

#### D4. MCP Server Support
Add Model Context Protocol server capability so AI agents can:
- Read/write files via MCP
- Execute commands via MCP
- Access project context

---

## Recommendation Matrix

| Goal | Best Option | Effort | Timeline |
|------|-------------|--------|----------|
| 64-bit ASAP | B (container2wasm) | Medium | 2-4 weeks |
| Best long-term | A (QEMU-Wasm) | High | 1-2 months |
| Quick improvement | D (Shell + Persistence) | Low | 1 week |
| Maximum flexibility | C (Hybrid) | Very High | 2-3 months |

## My Recommendation

**Start with D (Quick Wins) immediately**, then pursue **B (container2wasm)** for 64-bit.

### Phase 1: Quick Wins (This Week)
1. Add zsh + tmux to bootstrap script
2. Create pre-built AI agent bundle
3. Test if Claude Code npm actually works (Node 24 available!)

### Phase 2: container2wasm POC (Next 2 Weeks)
1. Build Docker image with all tools
2. Convert to WASM
3. Test loading in Apptron framework
4. Integrate networking (already have WebSocket bridge)

### Phase 3: Evaluate QEMU-Wasm (Later)
1. Monitor QEMU-Wasm development
2. Consider when their JIT support matures
3. May become drop-in replacement

---

## Technical Deep Dive: container2wasm Integration

### Step 1: Create AI Agent Docker Image

```dockerfile
# Dockerfile.ai-agent
FROM alpine:3.19

# Core tools
RUN apk add --no-cache \
    nodejs npm git curl wget \
    python3 py3-pip \
    zsh zsh-autosuggestions \
    tmux openssh-client \
    make gcc musl-dev

# Better shell
RUN chsh -s /bin/zsh root

# Node.js tools
RUN npm install -g @anthropic-ai/claude-code

# Python tools
RUN pip3 install anthropic google-generativeai openai

# Oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

WORKDIR /workspace
CMD ["/bin/zsh"]
```

### Step 2: Convert to WASM

```bash
# Install container2wasm
go install github.com/aspect-build/go-containerregistry@latest
go install github.com/ktock/container2wasm/cmd/c2w@latest

# Build and convert
docker build -t ai-sandbox:latest -f Dockerfile.ai-agent .
c2w ai-sandbox:latest ai-sandbox.wasm

# For browser, also generate JS wrapper
c2w --target=browser ai-sandbox:latest ai-sandbox-browser/
```

### Step 3: Integrate into Apptron

Modify `boot.go` to optionally load container2wasm instead of v86:

```go
// boot.go (conceptual)
func bootEnvironment(projectType string) {
    if projectType == "ai-agent" {
        // Load container2wasm WASM module
        loadContainer2Wasm("ai-sandbox.wasm")
    } else {
        // Existing v86 path
        loadV86Alpine()
    }
}
```

### Step 4: Connect Networking

Apptron's existing virtual network (go-netstack/vnet) can bridge to container2wasm:
- container2wasm supports gvisor-tap-vsock for networking
- Apptron already has WebSocket-to-TCP bridge
- Wire them together

---

## Resources

- [QEMU-Wasm GitHub](https://github.com/ktock/qemu-wasm)
- [container2wasm GitHub](https://github.com/ktock/container2wasm)
- [QEMU-Wasm Demo](https://ktock.github.io/qemu-wasm-demo/)
- [FOSDEM 2025 Talk: Running QEMU Inside Browser](https://fosdem.org/2025/schedule/event/fosdem-2025-6290-running-qemu-inside-browser/)
- [v86 GitHub](https://github.com/copy/v86) (current, 32-bit only)
- [WebContainers](https://webcontainers.io/) (alternative approach, closed-source)

---

## Next Steps

1. **Immediate:** Try `npm install -g @anthropic-ai/claude-code` in current Apptron (might just work!)
2. **This week:** Implement Quick Wins (zsh, tmux, better bootstrap)
3. **Next week:** POC container2wasm integration
4. **Decision point:** Evaluate whether to pursue QEMU-Wasm long-term
