#!/bin/sh
# Apptron Sandbox Stress Test
# Copy/paste this into your Apptron terminal to put the system through its paces

set -e
echo "=========================================="
echo "   APPTRON SANDBOX STRESS TEST"
echo "=========================================="
echo ""

# Colors for fun output (if terminal supports it)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

passed=0
failed=0

test_cmd() {
    name="$1"
    shift
    printf "%-40s" "Testing: $name..."
    if "$@" >/dev/null 2>&1; then
        echo "${GREEN}PASS${NC}"
        passed=$((passed + 1))
    else
        echo "${RED}FAIL${NC}"
        failed=$((failed + 1))
    fi
}

section() {
    echo ""
    echo "${BLUE}=== $1 ===${NC}"
}

# ============================================
section "SYSTEM BASICS"
# ============================================

test_cmd "uname" uname -a
test_cmd "hostname" hostname
test_cmd "whoami" whoami
test_cmd "pwd" pwd
test_cmd "date" date
test_cmd "uptime" uptime
test_cmd "cat /etc/os-release" cat /etc/os-release

echo ""
echo "System info:"
uname -a
cat /etc/os-release | head -3

# ============================================
section "FILESYSTEM OPERATIONS"
# ============================================

test_cmd "mkdir" mkdir -p /tmp/apptron-test
test_cmd "touch" touch /tmp/apptron-test/testfile
test_cmd "echo to file" sh -c 'echo "Hello Apptron" > /tmp/apptron-test/hello.txt'
test_cmd "cat file" cat /tmp/apptron-test/hello.txt
test_cmd "cp" cp /tmp/apptron-test/hello.txt /tmp/apptron-test/hello2.txt
test_cmd "mv" mv /tmp/apptron-test/hello2.txt /tmp/apptron-test/hello3.txt
test_cmd "ls" ls -la /tmp/apptron-test/
test_cmd "find" find /tmp/apptron-test -name "*.txt"
test_cmd "wc" wc -l /tmp/apptron-test/hello.txt
test_cmd "head" head -1 /tmp/apptron-test/hello.txt
test_cmd "tail" tail -1 /tmp/apptron-test/hello.txt
test_cmd "rm" rm /tmp/apptron-test/hello3.txt
test_cmd "rmdir" rm -rf /tmp/apptron-test

# ============================================
section "TEXT PROCESSING"
# ============================================

echo "The quick brown fox jumps over the lazy dog" > /tmp/test.txt
test_cmd "grep" grep "fox" /tmp/test.txt
test_cmd "sed" sed 's/fox/cat/' /tmp/test.txt
test_cmd "awk" awk '{print $1, $2, $3}' /tmp/test.txt
test_cmd "sort" sh -c 'echo -e "zebra\napple\nmango" | sort'
test_cmd "uniq" sh -c 'echo -e "a\na\nb" | uniq'
test_cmd "tr" sh -c 'echo "hello" | tr a-z A-Z'
test_cmd "cut" sh -c 'echo "a:b:c" | cut -d: -f2'
rm /tmp/test.txt

# ============================================
section "PACKAGE MANAGER (apk)"
# ============================================

echo "Updating package index..."
apk update

test_cmd "apk info" apk info
test_cmd "apk search" apk search python3

echo ""
echo "Installing packages (this tests network + package manager)..."
echo ""

# Install useful tools
for pkg in curl wget git python3 py3-pip nodejs npm vim nano htop; do
    printf "%-40s" "Installing: $pkg..."
    if apk add --no-cache "$pkg" >/dev/null 2>&1; then
        echo "${GREEN}OK${NC}"
        passed=$((passed + 1))
    else
        echo "${YELLOW}SKIP${NC} (may not exist for x86)"
        failed=$((failed + 1))
    fi
done

# ============================================
section "NETWORKING"
# ============================================

test_cmd "ping localhost" ping -c 1 127.0.0.1
test_cmd "curl (HTTP)" curl -s -o /dev/null -w "%{http_code}" https://httpbin.org/get
test_cmd "wget" wget -q -O /dev/null https://example.com
test_cmd "DNS lookup" nslookup google.com || host google.com || echo "no dns tools"

echo ""
echo "Fetching a webpage..."
curl -s https://httpbin.org/get | head -10

# ============================================
section "PYTHON"
# ============================================

if command -v python3 >/dev/null 2>&1; then
    echo "Python version: $(python3 --version)"

    test_cmd "python3 hello" python3 -c "print('Hello from Python!')"
    test_cmd "python3 math" python3 -c "import math; print(math.pi)"
    test_cmd "python3 json" python3 -c "import json; print(json.dumps({'test': 123}))"
    test_cmd "python3 http" python3 -c "import http.client; print('http module OK')"
    test_cmd "python3 os" python3 -c "import os; print(os.getcwd())"

    echo ""
    echo "Python one-liner - Fibonacci:"
    python3 -c "
fib = lambda n: n if n < 2 else fib(n-1) + fib(n-2)
print([fib(i) for i in range(10)])
"

    echo ""
    echo "Installing Python packages..."
    pip3 install --quiet requests 2>/dev/null && echo "requests: OK" || echo "requests: FAIL"

    echo ""
    echo "Testing HTTP request with Python:"
    python3 -c "
import urllib.request
resp = urllib.request.urlopen('https://httpbin.org/ip')
print('Your IP:', resp.read().decode()[:50])
" 2>/dev/null || echo "HTTP request failed"

else
    echo "Python3 not installed"
fi

# ============================================
section "NODE.JS"
# ============================================

if command -v node >/dev/null 2>&1; then
    echo "Node version: $(node --version)"
    echo "npm version: $(npm --version 2>/dev/null || echo 'not installed')"

    test_cmd "node hello" node -e "console.log('Hello from Node.js!')"
    test_cmd "node math" node -e "console.log(Math.PI)"
    test_cmd "node json" node -e "console.log(JSON.stringify({test: 123}))"
    test_cmd "node process" node -e "console.log(process.platform)"

    echo ""
    echo "Node one-liner - Async test:"
    node -e "
const delay = ms => new Promise(r => setTimeout(r, ms));
(async () => {
    console.log('Starting...');
    await delay(100);
    console.log('Done after 100ms!');
})();
"
else
    echo "Node.js not installed"
fi

# ============================================
section "GIT"
# ============================================

if command -v git >/dev/null 2>&1; then
    echo "Git version: $(git --version)"

    test_cmd "git init" sh -c 'cd /tmp && rm -rf test-repo && mkdir test-repo && cd test-repo && git init'
    test_cmd "git config" git config --global user.name "Test User" 2>/dev/null || true

    echo ""
    echo "Cloning a small repo..."
    cd /tmp
    rm -rf cowsay 2>/dev/null
    if git clone --depth 1 https://github.com/piuccio/cowsay.git 2>/dev/null; then
        echo "Clone: OK"
        ls cowsay/ | head -5
    else
        echo "Clone: FAIL (network issue?)"
    fi
else
    echo "Git not installed"
fi

# ============================================
section "PROCESS MANAGEMENT"
# ============================================

test_cmd "ps" ps aux
test_cmd "pgrep" pgrep -l . || true

echo ""
echo "Running processes:"
ps aux | head -10

echo ""
echo "Testing background jobs..."
sleep 1 &
SLEEP_PID=$!
test_cmd "background job" kill -0 $SLEEP_PID 2>/dev/null
kill $SLEEP_PID 2>/dev/null || true

# ============================================
section "COMPRESSION"
# ============================================

mkdir -p /tmp/compress-test
echo "test content" > /tmp/compress-test/file.txt

test_cmd "tar create" tar -cvf /tmp/test.tar -C /tmp compress-test
test_cmd "gzip" gzip /tmp/test.tar
test_cmd "gunzip" gunzip /tmp/test.tar.gz
test_cmd "tar extract" tar -xvf /tmp/test.tar -C /tmp

rm -rf /tmp/compress-test /tmp/test.tar 2>/dev/null

# ============================================
section "INTERACTIVE TOOLS (quick test)"
# ============================================

echo "Testing interactive tools (1 second each)..."

if command -v htop >/dev/null 2>&1; then
    timeout 1 htop -d 10 2>/dev/null || echo "htop: available (timeout expected)"
fi

if command -v top >/dev/null 2>&1; then
    echo "top: $(top -b -n 1 | head -5)"
fi

# ============================================
section "FUN STUFF"
# ============================================

echo ""
echo "ASCII Art time!"
echo ""

# Simple ASCII art without cowsay
cat << 'EOF'
    _____  ______ ______ _______  _____   _____ _   _
   /  _  \|   _  \   _  \__   __|/  _  \ /  _  \ | | |
  /  /_\  \  |_)  )  |_)  ) | |  /  /_\  \  | |  \ \ | |
 /  _____  \   __/   __/  | |  /  _____  \ | |   \ \| |
/_/     \_\_|   |_|      |_| /_/     \_\_| |_|    \___|

         Browser-based Linux Environment!
EOF

echo ""
echo "System resources:"
echo "  Memory: $(free -m 2>/dev/null | grep Mem | awk '{print $3"MB used / "$2"MB total"}' || echo 'N/A')"
echo "  Disk:   $(df -h / 2>/dev/null | tail -1 | awk '{print $3" used / "$2" total"}' || echo 'N/A')"

echo ""
echo "Generating some load..."
echo "  Calculating prime numbers..."
python3 -c "
import time
start = time.time()
primes = []
for n in range(2, 1000):
    if all(n % i != 0 for i in range(2, int(n**0.5)+1)):
        primes.append(n)
elapsed = time.time() - start
print(f'  Found {len(primes)} primes in {elapsed:.3f}s')
print(f'  Last 5: {primes[-5:]}')
" 2>/dev/null || echo "  (python not available)"

# ============================================
section "RESULTS"
# ============================================

echo ""
echo "=========================================="
echo "   TEST COMPLETE"
echo "=========================================="
echo ""
echo "  Passed: ${GREEN}$passed${NC}"
echo "  Failed: ${RED}$failed${NC}"
echo ""

if [ $failed -eq 0 ]; then
    echo "${GREEN}All tests passed! Your sandbox is working great.${NC}"
elif [ $failed -lt 5 ]; then
    echo "${YELLOW}Most tests passed. Some features may be limited.${NC}"
else
    echo "${RED}Several tests failed. Check the output above.${NC}"
fi

echo ""
echo "Try these next:"
echo "  - htop          # Interactive process viewer"
echo "  - python3       # Python REPL"
echo "  - node          # Node.js REPL"
echo "  - vim file.txt  # Text editor"
echo "  - ./sandbox-bootstrap.sh  # Install AI tools"
echo ""
