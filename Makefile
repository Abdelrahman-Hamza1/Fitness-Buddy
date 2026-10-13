# Fitness Buddy: the one entry point for local development and CI.
# The same targets run on a laptop and in GitHub Actions. CI overrides the tool
# paths on the command line, e.g. `make DOTNET=dotnet FLUTTER=flutter DART=dart check`.
# Run `make` or `make help` for the list of targets.

SHELL := bash
.SHELLFLAGS := -euo pipefail -c
# Targets run one at a time: the laptop has little free RAM (see S01 plan, R9).
.NOTPARALLEL:
.DELETE_ON_ERROR:
.DEFAULT_GOAL := help
MAKEFLAGS += --no-builtin-rules

REPO_ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# --- Toolchain (D1-D3) --------------------------------------------------------
# Flutter/Dart: pinned in .fvmrc, installed by tools/scripts/setup-flutter.sh.
FLUTTER_VERSION := $(shell python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))["flutter"])' '$(REPO_ROOT)/.fvmrc' 2>/dev/null)
ifeq ($(strip $(FLUTTER_VERSION)),)
$(error Could not read the "flutter" version from $(REPO_ROOT)/.fvmrc (is python3 installed?))
endif
FLUTTER_ROOT ?= $(HOME)/development/flutter-$(FLUTTER_VERSION)
FLUTTER ?= $(FLUTTER_ROOT)/bin/flutter
DART ?= $(FLUTTER_ROOT)/bin/dart

# .NET: pinned in backend/global.json, installed by tools/scripts/setup-dotnet.sh.
# Always run dotnet from backend/ (SDK and test-runner resolution follow the cwd).
# DOTNET_ROOT is exported so apphosts (e.g. MTP test executables) find the runtime.
DOTNET_ROOT ?= $(HOME)/.dotnet
DOTNET ?= $(DOTNET_ROOT)/dotnet
export DOTNET_ROOT
# The Host build generates its OpenAPI document by running plain `dotnet` from PATH
# (Microsoft.Extensions.ApiDescription.Server, S02 D9). On the laptop /usr/bin/dotnet is
# .NET 8, so the pinned SDK must come first.
export PATH := $(DOTNET_ROOT):$(PATH)
export DOTNET_CLI_TELEMETRY_OPTOUT := 1
export DOTNET_NOLOGO := 1

.PHONY: help
help: ## Show this list of targets
	@echo "Fitness Buddy: make <target>"
	@awk 'BEGIN { FS = ":.*## " } \
	  /^##@ / { printf "\n%s\n", substr($$0, 5); next } \
	  /^[a-zA-Z0-9_.-]+:.*## / { printf "  %-22s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo
	@echo "Pinned: Flutter $(FLUTTER_VERSION) (.fvmrc), .NET SDK from backend/global.json"

##@ Everyday (both stacks)

.PHONY: setup
setup: toolchain deps contract-tools ## First-time setup: install the pinned SDKs, fetch all dependencies, pull the contract tools

.PHONY: deps
deps: deps-dart deps-dotnet ## Fetch dependencies for the Dart workspace and the .NET backend

.PHONY: check
check: check-dart check-dotnet check-contract ## Format + static analysis for both stacks, then the API contract checks (no tests)

.PHONY: gen
gen: gen-contract gen-dart ## Regenerate everything derived from the contract: the bundle, then the Dart client

.PHONY: test
test: test-dart test-dotnet ## Run all tests, Dart then .NET

##@ Toolchain

.PHONY: doctor
doctor: ## Show tool versions, free disk/RAM; fail if the pinned SDKs are missing
	@FLUTTER='$(FLUTTER)' DART='$(DART)' DOTNET='$(DOTNET)' \
	  FLUTTER_VERSION='$(FLUTTER_VERSION)' \
	  FLUTTER_ROOT_ORIGIN='$(origin FLUTTER_ROOT)' DOTNET_ROOT_ORIGIN='$(origin DOTNET_ROOT)' \
	  bash '$(REPO_ROOT)/tools/scripts/doctor.sh'

.PHONY: toolchain
toolchain: toolchain-flutter toolchain-dotnet ## Install the pinned Flutter and .NET SDKs (user-local, no sudo)

.PHONY: toolchain-flutter
toolchain-flutter: ## Install the Flutter SDK from .fvmrc into ~/development (skips if present)
	@bash '$(REPO_ROOT)/tools/scripts/setup-flutter.sh' '$(FLUTTER_ROOT)'

.PHONY: toolchain-dotnet
toolchain-dotnet: ## Install the .NET SDK from backend/global.json into ~/.dotnet (skips if present)
	@bash '$(REPO_ROOT)/tools/scripts/setup-dotnet.sh' '$(DOTNET_ROOT)'

##@ .NET backend (backend/FitnessBuddy.slnx)

# Restore once in deps-dotnet. check-dotnet builds Release, and test-dotnet reuses
# that build (incremental, no restore), so `make deps-dotnet check-dotnet test-dotnet`
# compiles once. MSBuild switches can't be passed to `dotnet test` on MTP (they reach
# the test app), so node reuse is turned off through the environment for every call.
DOTNET_SLN := FitnessBuddy.slnx
export MSBUILDDISABLENODEREUSE := 1

.PHONY: deps-dotnet
deps-dotnet: ## Restore NuGet packages for the backend (audits for vulnerable packages)
	cd '$(REPO_ROOT)/backend' && '$(DOTNET)' restore $(DOTNET_SLN)

.PHONY: check-dotnet
check-dotnet: ## Verify C# formatting, then build Release with analyzers + warnings as errors
	cd '$(REPO_ROOT)/backend' && '$(DOTNET)' format whitespace $(DOTNET_SLN) --verify-no-changes
	cd '$(REPO_ROOT)/backend' && '$(DOTNET)' build $(DOTNET_SLN) -c Release --no-restore -m:4 -nodeReuse:false

.PHONY: test-dotnet
test-dotnet: ## Run the backend tests (xUnit v3 on Microsoft.Testing.Platform)
	cd '$(REPO_ROOT)/backend' && '$(DOTNET)' test --solution $(DOTNET_SLN) -c Release --no-restore --max-parallel-test-modules 2

##@ Dart workspace (pubspec.yaml, packages/, tools/)

# One pub workspace, one resolution, one pubspec.lock. `dart format .` and
# `dart analyze` only look at Dart files, so backend/ and spec/ are not touched.
# In CI (GitHub sets CI=true) pub must not re-resolve silently: `--enforce-lockfile`
# fails if pubspec.lock is missing or out of date. Locally the lockfile may change
# (that is how you update it); force the CI behaviour with PUB_GET_FLAGS=--enforce-lockfile.
ifeq ($(CI),true)
PUB_GET_FLAGS ?= --enforce-lockfile
endif
PUB_GET_FLAGS ?=
.PHONY: deps-dart
deps-dart: ## Resolve Dart dependencies for the whole workspace (flutter pub get at the root)
	cd '$(REPO_ROOT)' && '$(FLUTTER)' pub get $(PUB_GET_FLAGS)

.PHONY: check-dart
check-dart: ## Verify Dart formatting, then analyze with very_good_analysis (infos are errors)
	cd '$(REPO_ROOT)' && '$(DART)' format --output=none --set-exit-if-changed .
	cd '$(REPO_ROOT)' && '$(DART)' analyze --fatal-infos

.PHONY: test-dart
test-dart: ## Run the tests of every workspace member (flutter test or dart test), one at a time
	@DART='$(DART)' FLUTTER='$(FLUTTER)' bash '$(REPO_ROOT)/tools/scripts/dart-test-all.sh'

# The Dart API client (S02 D1, D2): generated from contracts/openapi.yaml into
# packages/fb_api_client and committed. gen-check is the CI guard: it regenerates
# and fails if the result differs from what git has. It compares the working tree
# with the index, so locally `git add` of a fresh regeneration counts as done (in
# CI the index is the commit). It doesn't bundle first: contract-bundle-check
# guards the bundle.
# Only the generated folders (gen-dart.sh writes nothing else): a hand edit
# elsewhere in the package is not a stale client.
GEN_DART_DIRS := packages/fb_api_client/lib/src/generated packages/fb_api_client/test/generated

.PHONY: gen-dart
gen-dart: ## Regenerate the Dart API client in packages/fb_api_client from contracts/openapi.yaml
	@DART='$(DART)' bash '$(REPO_ROOT)/tools/scripts/gen-dart.sh'

.PHONY: gen-check
gen-check: gen-dart ## Fail if the committed Dart API client is not what `make gen-dart` produces
	@stale="$$(git -C '$(REPO_ROOT)' status --porcelain --untracked-files=all -- $(GEN_DART_DIRS) | grep -v '^. ' || true)"; \
	if [[ -n "$$stale" ]]; then \
	  echo "Generated client is out of date: run 'make gen' and commit." >&2; \
	  echo "$$stale" | sed 's/^/  /' >&2; \
	  git -C '$(REPO_ROOT)' --no-pager diff --stat -- $(GEN_DART_DIRS) >&2; \
	  exit 1; \
	fi
	@echo "gen-check: OK, the generated code in packages/fb_api_client is up to date"

##@ API contract (contracts/, TD-023)

# Redocly (bundle), Spectral (lint) and oasdiff (breaking + conformance) run as
# Docker images pinned by digest in tools/contract-tools/compose.yaml (S02 D8):
# no network, the caller's uid:gid, the repo mounted read-only at /work. That
# file reads UID, GID and REPO_ROOT from the environment. Tool output goes to
# build/contract/, the only writable mount: every recipe that runs a tool
# creates it first (the scripts in tools/scripts do the same).
export UID := $(shell id -u)
export GID := $(shell id -g)
export REPO_ROOT
CONTRACT_COMPOSE := docker compose --progress quiet -f '$(REPO_ROOT)/tools/contract-tools/compose.yaml'
CONTRACT_RUN := $(CONTRACT_COMPOSE) run --rm -T
CONTRACT_BUILD := $(REPO_ROOT)/build/contract
# The server's build-time OpenAPI document (written by every Host build, S02 D9).
SERVER_DOC ?= $(REPO_ROOT)/backend/artifacts/openapi/server.json

# $(call bundle_contract,<output path in the repo>): Redocly bundles
# contracts/openapi/ (config: contracts/redocly.yaml), then a "generated" header
# is prepended. Redocly's log is shown only if it fails. Every line starts
# with @ (a multi-line variable expands to several recipe lines).
define bundle_contract
@mkdir -p '$(CONTRACT_BUILD)'
@if ! $(CONTRACT_RUN) -w /work/contracts redocly bundle openapi/openapi.yaml \
    --output /work/build/contract/redocly-bundle.yaml 2>'$(CONTRACT_BUILD)/redocly.log'; then \
  cat '$(CONTRACT_BUILD)/redocly.log' >&2; echo "Redocly could not bundle contracts/openapi/ (see above)." >&2; exit 1; fi
@{ echo '# GENERATED by `make gen-contract` (Redocly bundle of contracts/openapi/). Do not edit:'; \
  echo '# change the files in contracts/openapi/ and run `make gen`. See contracts/README.md.'; \
  cat '$(CONTRACT_BUILD)/redocly-bundle.yaml'; } > '$(REPO_ROOT)/$(1).tmp'
@mv '$(REPO_ROOT)/$(1).tmp' '$(REPO_ROOT)/$(1)'
endef

.PHONY: contract-tools
contract-tools: ## Pull the pinned contract tool images (Redocly, Spectral, oasdiff) if missing
	$(CONTRACT_COMPOSE) pull --policy missing
	@echo "contract-tools: images present:"; $(CONTRACT_COMPOSE) config --images | sed 's/^/  /'

.PHONY: gen-contract
gen-contract: ## Bundle contracts/openapi/ into contracts/openapi.yaml (commit the result)
	$(call bundle_contract,contracts/openapi.yaml)
	@echo "gen-contract: wrote contracts/openapi.yaml"

.PHONY: check-contract
check-contract: contract-bundle-check contract-lint contract-selftest contract-breaking contract-conformance ## All contract checks: bundle fresh, lint, self-test, breaking, conformance

.PHONY: contract-bundle-check
contract-bundle-check: ## Fail if contracts/openapi.yaml is not the current bundle of contracts/openapi/
	$(call bundle_contract,build/contract/openapi.yaml)
	@if ! diff -u --label 'contracts/openapi.yaml (current file)' --label 'contracts/openapi.yaml (fresh bundle of contracts/openapi/)' \
	    '$(REPO_ROOT)/contracts/openapi.yaml' '$(CONTRACT_BUILD)/openapi.yaml'; then \
	  echo "contract-bundle-check: contracts/openapi.yaml is stale: run 'make gen' and commit." >&2; exit 1; \
	fi
	@echo "contract-bundle-check: OK, contracts/openapi.yaml is up to date"

.PHONY: contract-lint
contract-lint: ## Lint the bundled contract with Spectral (contracts/spectral.yaml, warnings fail)
	@mkdir -p '$(CONTRACT_BUILD)'
	@$(CONTRACT_RUN) spectral lint contracts/openapi.yaml --ruleset contracts/spectral.yaml --fail-severity=warn
	@echo "contract-lint: OK"

.PHONY: contract-selftest
contract-selftest: ## Prove the contract checks still catch what they must (fixtures in contracts/selftest/)
	@bash '$(REPO_ROOT)/tools/scripts/contract-selftest.sh'

.PHONY: contract-breaking
contract-breaking: ## Breaking-change check vs the last contracts-v* tag (none yet: notice only; CONTRACT_BASE_REF=<ref> blocks)
	@bash '$(REPO_ROOT)/tools/scripts/contract-breaking.sh'

# contract-conformance builds the Host (Release, incremental: after check-dotnet only the
# document is regenerated) so server.json is never stale. The generator's cache only
# tracks the assembly, so it is deleted first: a deleted or hand-edited server.json, or
# changed generator options, would otherwise be left as is.
.PHONY: contract-conformance
contract-conformance: ## Build the Host (writes its OpenAPI document), then fail if it differs from the contract
	rm -f '$(REPO_ROOT)'/backend/src/Host/obj/*.OpenApiFiles.cache
	cd '$(REPO_ROOT)/backend' && '$(DOTNET)' build src/Host/FitnessBuddy.Host.csproj -c Release -nodeReuse:false -v:quiet -nologo
	@bash '$(REPO_ROOT)/tools/scripts/contract-conformance.sh' '$(REPO_ROOT)/contracts/openapi.yaml' '$(SERVER_DOC)'

##@ Traceability (AT-001)

# Release to report on: R1, R2, R3, Later or all (all adds the untagged IDs).
RELEASE ?= R1

.PHONY: trace
trace: ## Print the requirement coverage report (RELEASE=R1|R2|R3|Later|all, default R1)
	@cd '$(REPO_ROOT)' && '$(DART)' run tools/trace/bin/trace.dart --root . --release '$(RELEASE)'

# Later steps add: up/down (S03/S04), eval, catalog.
