# Changelog

## [0.1.1](https://github.com/casonadams/zload/compare/v0.1.0...v0.1.1) (2026-09-30)


### Features

* **build:** add post-install build hooks, self-compilation, and bootstrap installer ([c771502](https://github.com/casonadams/zload/commit/c7715024a0346598f7f8a30cff8939bd75b1a449))
* **cli:** add native zsh completions and plugin navigation helpers ([2a1688a](https://github.com/casonadams/zload/commit/2a1688ad0bd9e504eb735b7f550eb7f12d0215bb))
* **cli:** implement management commands, test suite, and startup benchmark ([717895e](https://github.com/casonadams/zload/commit/717895e4e43523296adf94faff9e9a54f01e581e))
* **compiler:** implement canonical ordering, bundle compiler, and ultra-fast warm path ([f10fdfe](https://github.com/casonadams/zload/commit/f10fdfe485664284e0f139ff928ca1e24eb6a76a))
* **completion:** enable lazy compinit automatically by default ([cd925ec](https://github.com/casonadams/zload/commit/cd925ec9593b412be5b0e505f916b6828dd9087c))
* **completions:** automatically discover and include ~/.zfunc in fpath ([dd30726](https://github.com/casonadams/zload/commit/dd30726a34a758ea4f8b51c12b0bceb9e88e6a11))
* **core:** implement bootstrap, declaration parser, and plugin locator ([eed9def](https://github.com/casonadams/zload/commit/eed9def34005f681268f42a7809a2770edd21909))
* **doctor:** add self-healing diagnostics, example configuration, and final verification runner ([cc609c8](https://github.com/casonadams/zload/commit/cc609c8dc56520033201abb12a3679a5021742f9))
* **eval:** add subshell eval caching and zero-fork verification tests ([9ba139b](https://github.com/casonadams/zload/commit/9ba139b221771336c838e68c75fcd42a50429efb))
* **events:** add directory-triggered lazy loading and path management helpers ([e4758b2](https://github.com/casonadams/zload/commit/e4758b2d5f6bdbae8aaf558a90d30803393b1c84))
* **gh-r:** add precompiled GitHub Releases binary asset management ([b45ceb4](https://github.com/casonadams/zload/commit/b45ceb49a2d840bfe0d77ef516097cd5d50e4d73))
* **hardening:** add concurrency locking, compinit detection, and failure resilience ([68e5439](https://github.com/casonadams/zload/commit/68e54397621d7639d7a500fcef0d92d3ee0fb8da))
* **lazy:** implement command proxy stubs, compinit deferral, and post-prompt scheduler ([9dbe708](https://github.com/casonadams/zload/commit/9dbe7080dddafd333e7ca6160a1f355f64cd361b))
* **omz:** add Oh-My-Zsh and Prezto compatibility shims and release automation ([eafc2e7](https://github.com/casonadams/zload/commit/eafc2e728d3d5d38978a15765486e55e26b052fc))
* **snippet:** add remote snippet downloading and monorepo subpath targeting ([c6d63cb](https://github.com/casonadams/zload/commit/c6d63cb336c70f4f35bcd17c308d2d18a6ce943f))
* **sync:** add reproducible lockfiles and machine synchronization ([566f9dd](https://github.com/casonadams/zload/commit/566f9dd9e7e9e5730d739a958fce12df2699c7b7))
* **update:** add -f/--force flag to discard local working tree changes ([709aa13](https://github.com/casonadams/zload/commit/709aa13e4522f401473859a8757cb74e909316ea))
* **upgrade:** add -f/--force flag and show detailed git error output ([37f7745](https://github.com/casonadams/zload/commit/37f77458a5aee3aebc10171c7d361123f067699b))
* **upgrade:** add zload upgrade and self-update commands ([78cf74d](https://github.com/casonadams/zload/commit/78cf74d153e6b6e041ac0b15c2c9ed69f11b2d79))


### Bug Fixes

* **ci:** enable GitHub Pages configuration in workflow ([f200122](https://github.com/casonadams/zload/commit/f2001229dcb67dc796a888a65e7bcd2bc00a1b44))
* **ci:** install man-db on Linux CI and add resilient manpage path resolution ([99135b6](https://github.com/casonadams/zload/commit/99135b60021e2c24e44c3bcdccfd5a6a78d16913))
* **ci:** use sudo for shellspec installation on Ubuntu runner ([f2bfe39](https://github.com/casonadams/zload/commit/f2bfe396038d5ec09e409de787d4efe13f73f45c))
* **compile:** enable extended_glob to compile plugin zsh and sh scripts ([6c57c3d](https://github.com/casonadams/zload/commit/6c57c3dbfdbfd598e6f5fc0c1e6bb9d0a8da3026))
* **completion:** forward lazy compinit widget without dot prefix ([38dd757](https://github.com/casonadams/zload/commit/38dd7574706edfb011255419be42fa41c77535e7))
* **core:** ensure upgrade recompiles modules and clears runtime cache ([e23cfce](https://github.com/casonadams/zload/commit/e23cfce35134df608794df204b96be9a453d7226))
* **loader:** resolve theme filenames without owner prefixes and clean update loop variables ([9aae93f](https://github.com/casonadams/zload/commit/9aae93fea9432fd8d76aa66103466372700c57fa))
* **profile:** expand prompt ANSI colors properly in zload profile output ([2e29519](https://github.com/casonadams/zload/commit/2e295192ef391f75ae17b8e693647b956c9bb195))
* **update:** silence interactive job control messages and preserve plugin order ([59a64dc](https://github.com/casonadams/zload/commit/59a64dc4e0c08280e1e05c2db9608ccea7686cfc))


### Performance Improvements

* **bundle:** eliminate subshell fork in _zload_hash and optimize bundle initialization ([4a82065](https://github.com/casonadams/zload/commit/4a8206549445c5a594e11f2315507dc36a2ed77f))
* **bundle:** inline command stubs and batch deferred hooks into wordcode ([9047ea4](https://github.com/casonadams/zload/commit/9047ea476e4fd142b801e5ceb52e667edd15f42c))
* **compile:** auto-compile plugin entry scripts and top-level modules to zwc ([6c1afba](https://github.com/casonadams/zload/commit/6c1afbaea33619ef4f36e53b370dce64cce48f80))
* **core:** guard cache and plugins directory creation to eliminate startup fork ([3b8dfd1](https://github.com/casonadams/zload/commit/3b8dfd131949b142f2179dce361de7ff7def3ad7))
* **eval:** guard cache directory creation in _zload_eval ([2d0ee6f](https://github.com/casonadams/zload/commit/2d0ee6fe43eb74c2ad7017f8b196a337b1c93c9b))
* **gh-r:** use native Zsh parameters and case expansion to eliminate subprocess forks in _zload_install_gh_r ([1f44dc1](https://github.com/casonadams/zload/commit/1f44dc1c5b7514e835d2c2525d3150b1218d31e9))
* **path:** eliminate redundant inner-loop array copying in _zload_add_paths ([8d690a9](https://github.com/casonadams/zload/commit/8d690a909a81fac993e9dfa27f1f9e39ff4dbbe6))
* **update:** compile updated plugin scripts to zwc wordcode ([85ea45e](https://github.com/casonadams/zload/commit/85ea45e8b0f58ca1b3f7282139008c9fb121520f))
