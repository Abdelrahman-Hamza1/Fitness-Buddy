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
export DOTNET_CLI_TELEMETRY_OPTOUT := 1
export DOTNET_NOLOGO := 1

.PHONY: help
help: ## Show this list of targets
	@echo "Fitness Buddy: make <target>"
	@awk 'BEGIN { FS = ":.*## " } \
	  /^##@ / { printf "\n%s\n", substr($$0, 5); next } \
	  /^[a-zA-Z0-9_.-]+:.*## / { printf "  %-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo
	@echo "Pinned: Flutter $(FLUTTER_VERSION) (.fvmrc), .NET SDK from backend/global.json"

##@ Everyday (both stacks)

.PHONY: setup
setup: toolchain deps ## First-time setup: install the pinned SDKs, then fetch all dependencies

.PHONY: deps
deps: deps-dart deps-dotnet ## Fetch dependencies for the Dart workspace and the .NET backend

.PHONY: check
check: check-dart check-dotnet ## Format + static analysis for both stacks (no tests)

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

##@ Traceability (AT-001)

# Release to report on: R1, R2, R3, Later or all (all adds the untagged IDs).
RELEASE ?= R1

.PHONY: trace
trace: ## Print the requirement coverage report (RELEASE=R1|R2|R3|Later|all, default R1)
	@cd '$(REPO_ROOT)' && '$(DART)' run tools/trace/bin/trace.dart --root . --release '$(RELEASE)'

# Later steps add: gen (S02), up/down (S03/S04), eval, catalog.
