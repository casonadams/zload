#!/usr/bin/env zsh
set -e

print -P "%F{cyan}========================================%f"
print -P "%F{cyan}        zload Full Test Suite          %f"
print -P "%F{cyan}========================================%f\n"

print -P "%F{blue}==> Syntax validation (zsh -n)...%f"
zsh -n zload.zsh zload.plugin.zsh
for f in functions/*; do
  [[ "$f" == *.zwc ]] && continue
  zsh -n "$f"
done
for t in test/*.zsh; do
  zsh -n "$t"
done
print -P "%F{green}[OK] All syntax checks passed.%f\n"

print -P "%F{blue}==> Slice 1: Core Loader & Specification Parser...%f"
zsh test/test_bootstrap.zsh
zsh test/test_parser.zsh
zsh test/test_find_file.zsh
zsh test/test_install.zsh
print -P "%F{green}[OK] Slice 1 passed.%f\n"

print -P "%F{blue}==> Slice 2: Oh-My-Zsh & Prezto Compatibility Shims...%f"
zsh test/test_omz.zsh
zsh test/test_prezto.zsh
zsh test/test_real_omz.zsh
print -P "%F{green}[OK] Slice 2 passed.%f\n"

print -P "%F{blue}==> Slice 3: Lazy Loading Primitives...%f"
zsh test/test_lazy_cmd.zsh
zsh test/test_lazy_compinit.zsh
zsh test/test_defer.zsh
zsh test/test_eval.zsh
print -P "%F{green}[OK] Slice 3 passed.%f\n"

print -P "%F{blue}==> Slice 4: Bundle Compiler & Ultra-Fast Warm Startup...%f"
zsh test/test_order.zsh
zsh test/test_bundle.zsh
zsh test/test_warm_startup.zsh
zsh test/test_zero_forks.zsh
print -P "%F{green}[OK] Slice 4 passed.%f\n"

print -P "%F{blue}==> Slice 5: CLI Management & Quality Assurance...%f"
zsh test/test_cli.zsh
zsh test/test_update.zsh
zsh test/test_doctor.zsh
print -P "%F{green}[OK] Slice 5 passed.%f\n"

print -P "%F{blue}==> Slice 6: Remote Snippets & Monorepo Subpath Loading...%f"
zsh test/test_snippet.zsh
zsh test/test_subpath.zsh
print -P "%F{green}[OK] Slice 6 passed.%f\n"

print -P "%F{blue}==> Slice 7: Post-Install Build Hooks & Self-Optimization...%f"
zsh test/test_build.zsh
zsh test/test_self_compile.zsh
zsh test/test_installer.zsh
print -P "%F{green}[OK] Slice 7 passed.%f\n"

print -P "%F{blue}==> Slice 8: Hardening, Concurrency Locks & Real-World Edge Cases...%f"
zsh test/test_edge_cases.zsh
zsh test/test_concurrency.zsh
print -P "%F{green}[OK] Slice 8 passed.%f\n"

print -P "%F{green}========================================%f"
print -P "%F{green}  ALL TESTS PASSED SUCCESSFULLY!        %f"
print -P "%F{green}========================================%f"
