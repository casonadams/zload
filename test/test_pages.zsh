#!/usr/bin/env zsh
set -e

# Assert website files exist
[[ -f "www/index.html" ]] || { echo "FAIL: www/index.html missing"; exit 1; }
[[ -f "www/docs.html" ]] || { echo "FAIL: www/docs.html missing"; exit 1; }
[[ -f "www/css/style.css" ]] || { echo "FAIL: www/css/style.css missing"; exit 1; }
[[ -f "www/favicon.svg" ]] || { echo "FAIL: www/favicon.svg missing"; exit 1; }
[[ -f ".github/workflows/pages.yml" ]] || { echo "FAIL: pages.yml workflow missing"; exit 1; }

# Assert index.html has critical tags
grep -q "<title>" "www/index.html" || { echo "FAIL: title tag missing in index.html"; exit 1; }
grep -q "viewport" "www/index.html" || { echo "FAIL: viewport meta missing in index.html"; exit 1; }
grep -q "zload" "www/index.html" || { echo "FAIL: zload missing in index.html"; exit 1; }

# Assert docs.html has critical tags
grep -q "<title>" "www/docs.html" || { echo "FAIL: title tag missing in docs.html"; exit 1; }
grep -q "zload path" "www/docs.html" || { echo "FAIL: zload path missing in docs.html"; exit 1; }

echo "PASS: test_pages (GitHub Pages website artifacts and deployment workflow verified)"
