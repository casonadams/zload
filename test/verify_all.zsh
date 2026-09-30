#!/usr/bin/env zsh
set -e

print -P "%F{cyan}================================================================%f"
print -P "%F{cyan}            zload Specification Final Verification              %f"
print -P "%F{cyan}================================================================%f\n"

# Gate 1: Lint & Quality Gate
print -P "%F{blue}[Gate 1/5] Running lint, syntax, and Ripwire quality checks...%f"
./scripts/lint
print -P "%F{green}✓ Gate 1 Passed: 100%% clean syntax and quality gates.%f\n"

# Gate 2: Full Test Suite
print -P "%F{blue}[Gate 2/5] Running complete test suite (all slices)...%f"
zsh test/run_all.zsh >/dev/null
print -P "%F{green}✓ Gate 2 Passed: Full unit and integration suite passing.%f\n"

# Gate 3: Warm Benchmark
print -P "%F{blue}[Gate 3/5] Measuring warm interactive startup latency...%f"
BENCH_OUTPUT=$(zsh benchmark/bench.zsh)
print "$BENCH_OUTPUT" | grep -A 4 "Scenario"
if print "$BENCH_OUTPUT" | grep -q "\[PASS\]"; then
  print -P "%F{green}✓ Gate 3 Passed: Warm startup overhead is strictly < 2.0 ms.%f\n"
else
  print -u2 -P "%F{red}✗ Gate 3 Failed: Warm benchmark latency above budget.%f"
  exit 1
fi

# Gate 4: Zero-Fork Subprocess Verification
print -P "%F{blue}[Gate 4/5] Verifying zero subprocess forks on warm startup...%f"
zsh test/test_zero_forks.zsh >/dev/null
print -P "%F{green}✓ Gate 4 Passed: Zero child processes spawned in warm path.%f\n"

# Gate 5: Real-World Oh-My-Zsh Integration
print -P "%F{blue}[Gate 5/5] Verifying real-world Oh-My-Zsh git branch integration...%f"
zsh test/test_real_omz.zsh >/dev/null
print -P "%F{green}✓ Gate 5 Passed: Oh-My-Zsh shims and current_branch verified.%f\n"

print -P "%F{green}================================================================%f"
print -P "%F{green}  ALL 5 SPECIFICATION GATES PASSED! READY FOR PRODUCTION.       %f"
print -P "%F{green}================================================================%f"
