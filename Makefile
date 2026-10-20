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

# Android: Temurin JDK 21 + Android SDK, pinned in tools/scripts/setup-android.sh
# (S06 plan D19). Exported so Flutter, Gradle and sdkmanager use them. A value in
# the environment wins over these defaults: CI sets the runner's JDK 21 and SDK;
# on the laptop a shell-exported JAVA_HOME must be unset or point here (`make
# doctor` shows the one used). The JDK dir name is the pinned build: bump it
# together with the script.
JAVA_HOME ?= $(HOME)/development/jdk-21.0.12.1+1
ANDROID_HOME ?= $(HOME)/development/android-sdk
export JAVA_HOME ANDROID_HOME

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
setup: toolchain deps contract-tools catalog-pack ## First-time setup: install the pinned SDKs, fetch all dependencies, pull the contract tools, build the bundled catalog pack

.PHONY: deps
deps: deps-dart deps-dotnet ## Fetch dependencies for the Dart workspace and the .NET backend

.PHONY: check
check: check-dart check-dotnet check-contract apk-hardening-selftest ## Format + static analysis for both stacks, the API contract checks, the APK hardening self-test (no tests)

.PHONY: gen
gen: gen-contract gen-dart gen-app gen-sync-schemas ## Regenerate all committed generated code: contract bundle, Dart client, app l10n + providers

.PHONY: test
test: test-dart test-dotnet ## Run all tests, Dart then .NET

##@ Toolchain

.PHONY: doctor
doctor: ## Show tool versions, free disk/RAM; fail if the pinned SDKs are missing
	@FLUTTER='$(FLUTTER)' DART='$(DART)' DOTNET='$(DOTNET)' \
	  FLUTTER_VERSION='$(FLUTTER_VERSION)' \
	  FLUTTER_ROOT_ORIGIN='$(origin FLUTTER_ROOT)' DOTNET_ROOT_ORIGIN='$(origin DOTNET_ROOT)' \
	  JAVA_HOME_ORIGIN='$(origin JAVA_HOME)' ANDROID_HOME_ORIGIN='$(origin ANDROID_HOME)' \
	  bash '$(REPO_ROOT)/tools/scripts/doctor.sh'

.PHONY: toolchain
toolchain: toolchain-flutter toolchain-dotnet toolchain-android ## Install the pinned Flutter, .NET and Android toolchains (user-local, no sudo)

.PHONY: toolchain-android
toolchain-android: ## Install JDK 21 + the Android SDK into ~/development and accept the SDK licences (skips what is present)
	@bash '$(REPO_ROOT)/tools/scripts/setup-android.sh' '$(JAVA_HOME)' '$(ANDROID_HOME)'

# CI (jobs android, android-it): the runner brings JDK 21 and an SDK; this adds
# only the SDK packages the build needs (NDK, CMake, ...), from the same list.
.PHONY: toolchain-android-sdk
toolchain-android-sdk: ## Install the pinned SDK packages into an existing SDK at ANDROID_HOME (CI: the runner's), using the JDK at JAVA_HOME
	@bash '$(REPO_ROOT)/tools/scripts/setup-android.sh' --sdk-only '$(ANDROID_HOME)'

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
test-dotnet: catalog-pack catalog-client-smoke ## Run the backend tests (xUnit v3 on Microsoft.Testing.Platform)
	cd '$(REPO_ROOT)/backend' && '$(DOTNET)' test --solution $(DOTNET_SLN) -c Release --no-restore --max-parallel-test-modules 2

##@ Local backend containers

API_COMPOSE := docker compose -f '$(REPO_ROOT)/infra/compose/docker-compose.yml'

.PHONY: up
up: ## Build and start api + worker + Postgres, apply migrations, then wait for readiness
	$(API_COMPOSE) up -d --build --force-recreate migrate api worker postgres
	@for attempt in {1..30}; do \
	  if curl --fail --silent --max-time 1 http://127.0.0.1:5198/health/ready >/dev/null; then \
	    echo 'API ready: http://127.0.0.1:5198'; exit 0; \
	  fi; sleep 1; \
	done; $(API_COMPOSE) logs api; echo 'API readiness timed out' >&2; exit 1

.PHONY: down
down: ## Stop local backend containers and network (preserves database volume)
	$(API_COMPOSE) down

.PHONY: image-smoke
image-smoke: ## Build and smoke-test the non-root API image, exporters and process lifecycle
	@bash '$(REPO_ROOT)/tools/scripts/image-smoke.sh'

.PHONY: sync-spike
sync-spike: ## Run authenticated sync convergence/fault/10000-row checks against isolated Docker API + Postgres
	@DART='$(DART)' bash '$(REPO_ROOT)/tools/scripts/sync-spike.sh'

##@ Dart workspace (pubspec.yaml, apps/, packages/, tools/)

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
check-dart: ## Verify Dart formatting, analyze (very_good_analysis + riverpod_lint, infos are errors), app-check, frozen migrations
	cd '$(REPO_ROOT)' && '$(DART)' format --output=none --set-exit-if-changed .
	cd '$(REPO_ROOT)' && '$(DART)' analyze --fatal-infos
	$(APP_CHECK)
	@bash '$(REPO_ROOT)/tools/scripts/check-frozen-migrations-selftest.sh'
	@bash '$(REPO_ROOT)/tools/scripts/check-frozen-migrations.sh'
	PYTHONDONTWRITEBYTECODE=1 python3 -I -m unittest discover -s '$(REPO_ROOT)/tools/scripts' -p 'test_off*.py'

# The app's architecture rules the analyzer can't express (S06 plan D16):
# import boundaries, the single-writer write path (A01 D12), raw user-facing
# strings, left/right layout. Part of check-dart, so CI's dart job runs it.
# Rules: tools/app_check/README.md.
# `--package` checks the design system's lib/ with the two lexical rules only
# (A02 D17): no raw UI strings, no left/right layout.
APP_CHECK_BIN = cd '$(REPO_ROOT)' && '$(DART)' run tools/app_check/bin/app_check.dart
APP_CHECK = $(APP_CHECK_BIN) apps/mobile && $(APP_CHECK_BIN) --package packages/fb_design_system
.PHONY: app-check
app-check: ## Check apps/mobile/lib (import boundaries, single-writer write path, raw UI strings, left/right layout) and packages/fb_design_system/lib (raw UI strings, left/right layout)
	$(APP_CHECK)

.PHONY: test-dart
test-dart: ## Run the tests of every workspace member (flutter test or dart test), one at a time
	@DART='$(DART)' FLUTTER='$(FLUTTER)' bash '$(REPO_ROOT)/tools/scripts/dart-test-all.sh'

# Committed generated Dart code: the API client (S02 D1, D2), generated from
# contracts/openapi.yaml into packages/fb_api_client, and the app's gen-l10n and
# Riverpod output (S06 plan D14). gen-check is the CI guard: it regenerates
# and fails if the result differs from what git has. It compares the working tree
# with the index, so locally `git add` of a fresh regeneration counts as done (in
# CI the index is the commit). It doesn't bundle first: contract-bundle-check
# guards the bundle.
# Only the generated paths (gen-dart.sh and gen-app.sh write nothing else): a
# hand edit elsewhere is not stale generated code. The app's paths: gen-l10n
# output and riverpod_generator's *.g.dart files (S06 plan D14).
# drift (A01 D15): its *.g.dart (build_runner), the migration steps
# (lib/**/*.steps.dart) and the schema classes of the migration tests
# (test/drift/*/generated), all derived from apps/mobile/drift_schemas/, and
# the *.g.dart of test-only drift databases (test/**/*.g.dart, A01 WP3).
GEN_DART_DIRS := packages/fb_api_client/lib/src/generated packages/fb_api_client/test/generated \
  apps/mobile/lib/l10n/gen packages/fb_design_system/lib/l10n/gen \
  ':(glob)apps/mobile/lib/**/*.g.dart' \
  ':(glob)apps/mobile/lib/**/*.steps.dart' ':(glob)apps/mobile/test/**/*.g.dart' \
  ':(glob)apps/mobile/test/drift/*/generated/**'

.PHONY: gen-dart
gen-dart: ## Regenerate the Dart API client in packages/fb_api_client from contracts/openapi.yaml
	@DART='$(DART)' bash '$(REPO_ROOT)/tools/scripts/gen-dart.sh'

.PHONY: gen-app
gen-app: ## Regenerate the app's committed code in apps/mobile: gen-l10n (lib/l10n/gen), Riverpod + drift (*.g.dart), drift migration steps + test schemas
	@DART='$(DART)' FLUTTER='$(FLUTTER)' bash '$(REPO_ROOT)/tools/scripts/gen-app.sh'

.PHONY: gen-check
gen-check: gen-dart gen-app check-sync-schemas ## Fail if the committed generated Dart code (API client, app) is not what `make gen-dart gen-app` produces
	@stale="$$(git -C '$(REPO_ROOT)' status --porcelain --untracked-files=all -- $(GEN_DART_DIRS) | grep -v '^. ' || true)"; \
	if [[ -n "$$stale" ]]; then \
	  echo "Generated Dart code is out of date: run 'make gen' and commit." >&2; \
	  echo "$$stale" | sed 's/^/  /' >&2; \
	  git -C '$(REPO_ROOT)' --no-pager diff --stat -- $(GEN_DART_DIRS) >&2; \
	  exit 1; \
	fi
	@echo "gen-check: OK, the generated code in packages/fb_api_client and apps/mobile is up to date"

##@ Mobile app (apps/mobile)

# Database schema changes (A01 D15): change the tables, bump schemaVersion in
# lib/core/db/app_database.dart, then run this. It dumps the new version to
# drift_schemas/, regenerates the steps and the migration test schemas, and
# prints the step to write in lib/core/db/migrations/from_<n>_to_<n+1>.dart.
# Shipped dumps and steps are frozen (tools/scripts/check-frozen-migrations.sh).
.PHONY: db-migrations
db-migrations: ## After a schema change: dump the new drift schema version, regenerate steps + migration tests (apps/mobile)
	cd '$(REPO_ROOT)/apps/mobile' && '$(DART)' run build_runner build
	cd '$(REPO_ROOT)/apps/mobile' && '$(DART)' run drift_dev make-migrations
	cd '$(REPO_ROOT)/apps/mobile' && '$(DART)' format lib/core/db test/drift

# Goldens are alchemist's CI variant only (S06 plan D17): text renders as blocks,
# so the images are identical on the laptop and in CI. `make test-dart` compares
# them; this target rewrites them after an intended UI change (review the PNGs).
.PHONY: goldens
goldens: ## Regenerate the golden images of packages/fb_design_system and apps/mobile (test/**/goldens/ci), then review and commit them
	cd '$(REPO_ROOT)/packages/fb_design_system' && '$(FLUTTER)' test --update-goldens --tags golden
	cd '$(REPO_ROOT)/apps/mobile' && '$(FLUTTER)' test --update-goldens --tags golden

# Android builds (S06 plan D4-D7, A6, A8). Flavors: dev (local API over adb
# reverse), staging, prod; each installs side by side. The flavor's Dart config
# is apps/mobile/config/$(FLAVOR).json (--dart-define-from-file).
# Release signing: the stable key from the environment (CI secrets) or from
# FB_RELEASE_ENV (laptop; `FB_RELEASE_ENV=` to ignore it); without one, *-debugkey.*
# outputs (why: docs/runbooks/android-signing.md).
# Every target stops the Gradle daemons afterwards (7 GB laptop).
FLAVOR ?= staging
MODE ?= release
BUILD_NUMBER ?=
FB_RELEASE_ENV ?= $(HOME)/.fitness-buddy/keys/release.env
ADB := $(ANDROID_HOME)/platform-tools/adb
# The local API's port (backend/README.md): `make run-dev` forwards it from the phone.
DEV_API_PORT := 5198
COLD_START_APP ?= io.github.abdelrahmanhamza1.fitnessbuddy.staging
RUNS ?= 10

.PHONY: build-android
build-android: catalog-pack ## Build FLAVOR=staging|prod|dev: release APK (arm64) + AAB, checked (no cleartext, signer); MODE=debug for a debug APK; BUILD_NUMBER=n
	@FLUTTER='$(FLUTTER)' REPO_ROOT='$(REPO_ROOT)' FLAVOR='$(FLAVOR)' MODE='$(MODE)' \
	  BUILD_NUMBER='$(BUILD_NUMBER)' FB_RELEASE_ENV='$(FB_RELEASE_ENV)' \
	  bash '$(REPO_ROOT)/tools/scripts/build-android.sh'

# Installs what `make build-android` built (same FLAVOR and MODE) on the one
# connected phone: the owner's A55 sessions (A02 D18). The release-key APK, or
# the *-debugkey.apk a machine without the key produces.
.PHONY: install-android
install-android: ## Install the APK that build-android built (FLAVOR=staging|prod|dev, MODE) on the connected phone with adb install -r
	@apk_dir='$(REPO_ROOT)/apps/mobile/build/app/outputs/flutter-apk'; \
	apk="$$apk_dir/app-$(FLAVOR)-$(MODE).apk"; \
	[[ -f "$$apk" ]] || apk="$$apk_dir/app-$(FLAVOR)-$(MODE)-debugkey.apk"; \
	if [[ ! -f "$$apk" ]]; then \
	  echo "install-android: no APK for FLAVOR=$(FLAVOR) MODE=$(MODE) in $$apk_dir: run 'make build-android FLAVOR=$(FLAVOR)' first" >&2; exit 1; fi; \
	if ! '$(ADB)' get-state >/dev/null 2>&1; then \
	  echo "install-android: no single device: connect the phone (USB or Wireless debugging) and allow it; with several, set ANDROID_SERIAL" >&2; exit 1; fi; \
	echo "install-android: installing $$apk"; \
	'$(ADB)' $(if $(ANDROID_SERIAL),-s '$(ANDROID_SERIAL)') install -r "$$apk"

# No Android SDK needed: it runs the check on captured aapt2 dumps.
.PHONY: apk-hardening-selftest
apk-hardening-selftest: ## Prove the release APK hardening check still catches what it must (fixtures in tools/scripts/testdata/apk-hardening/)
	@bash '$(REPO_ROOT)/tools/scripts/apk-hardening-selftest.sh'

.PHONY: run-dev
run-dev: catalog-pack ## Run the dev flavor on the connected phone (debug, hot reload) against the local API on port 5198 (adb reverse)
	@if ! '$(ADB)' get-state >/dev/null 2>&1; then \
	  echo "run-dev: no single device: connect the phone (USB or Wireless debugging) and allow it; with several, set ANDROID_SERIAL" >&2; exit 1; fi
	'$(ADB)' reverse tcp:$(DEV_API_PORT) tcp:$(DEV_API_PORT)
	@status=0; \
	cd '$(REPO_ROOT)/apps/mobile' && '$(FLUTTER)' run --flavor dev --dart-define-from-file=config/dev.json \
	  $(if $(ANDROID_SERIAL),-d '$(ANDROID_SERIAL)') || status=$$?; \
	(cd '$(REPO_ROOT)/apps/mobile/android' && ./gradlew --stop -q >/dev/null 2>&1) || true; \
	exit $$status

# Integration tests (S06 plan D18): Patrol, apps/mobile/patrol_test/, dev flavor
# with config/dev.json (no API reachable on an emulator). patrol_cli is pinned
# here and pairs with the `patrol` pin in apps/mobile/pubspec.yaml (bump both,
# compatibility table at patrol.leancode.co); activated globally when missing
# or at another version. PATROL_ARGS passes extra flags (e.g. --verbose).
# test-it needs one running emulator or connected phone (never an emulator on
# the 7 GB laptop: CI's android-it job runs it); build-it needs no device.
PATROL_CLI_VERSION := 4.8.0
PATROL_ARGS ?=
PATROL_ANDROID = @DART='$(DART)' FLUTTER='$(FLUTTER)' REPO_ROOT='$(REPO_ROOT)' \
  PATROL_CLI_VERSION='$(PATROL_CLI_VERSION)' PATROL_ARGS='$(PATROL_ARGS)' \
  bash '$(REPO_ROOT)/tools/scripts/patrol-android.sh'

.PHONY: test-it
test-it: catalog-pack ## Run the Patrol integration tests (patrol_test/, dev flavor) on the one connected emulator or phone
	$(PATROL_ANDROID) test

.PHONY: build-it
build-it: catalog-pack ## Build the Patrol test APKs (dev debug app + instrumentation APK), no device needed
	$(PATROL_ANDROID) build

.PHONY: cold-start
cold-start: ## Measure cold start on the connected phone: 1 warm-up + RUNS=10 `am start -W`, median + p90 (COLD_START_APP=<application id>)
	@ADB='$(ADB)' bash '$(REPO_ROOT)/tools/scripts/cold-start.sh' '$(COLD_START_APP)' '$(RUNS)'

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

##@ Food catalog (A03, A05)

# USDA_DIR=<dir with sr_legacy/ and foundation/> reuses an earlier download.
.PHONY: catalog-usda
catalog-usda: ## Download the pinned USDA CSVs to a temp dir, then rewrite data/usda/extract.jsonl from data/usda_selection.yaml
	@set -e; tmp=""; dir='$(USDA_DIR)'; \
	if [ -z "$$dir" ]; then tmp="$$(mktemp -d)"; trap 'rm -rf "$$tmp"' EXIT; \
	  bash '$(REPO_ROOT)/tools/scripts/fetch-usda.sh' "$$tmp/raw"; dir="$$tmp/raw"; fi; \
	cd '$(REPO_ROOT)' && '$(DART)' run tools/catalog/bin/catalog.dart import-usda --usda-dir "$$dir"

CATALOG := cd '$(REPO_ROOT)' && '$(DART)' run tools/catalog/bin/catalog.dart
CATALOG_ASSETS := apps/mobile/assets/catalog

.PHONY: catalog
catalog: ## A05: validate, append new IDs to data/catalog_ids.lock, bump data/catalog_release.yaml, build build/catalog/ and the app assets, print the must-cover table. Commit what it changes. CATALOG_DRAFTS=1 packs drafts too (dev)
	$(CATALOG) build --update --coverage --assets-dir $(CATALOG_ASSETS) $(if $(CATALOG_DRAFTS),--include-drafts)
	$(CATALOG) emit-sql

.PHONY: catalog-pack
catalog-pack: ## A05: non-mutating: validate, build the release pack (no drafts) and copy it to the app assets; fails if the lock or version is stale
	$(CATALOG) build --assets-dir $(CATALOG_ASSETS)

.PHONY: catalog-check
catalog-check: ## A05: CI checks, write nothing under data/: validation, ID lock vs the merge base (CATALOG_BASE_REF), freshness, schemas, size, AT-003 coverage, fixture SQL
	$(CATALOG) check
	$(CATALOG) emit-sql --check

.PHONY: off-coverage
off-coverage: ## A03: unit-test the script, then download the OFF export (~0.9 GB, needs 2 GB free) and print region coverage as Markdown (not in CI)
	PYTHONDONTWRITEBYTECODE=1 python3 -I -m unittest discover -s '$(REPO_ROOT)/tools/scripts' -p 'test_off*.py'
	bash '$(REPO_ROOT)/tools/scripts/off-coverage.sh'

##@ Buddy interpretation spike (B02)

BUDDY_SPIKE_PROJECT := tools/BuddySpike/FitnessBuddy.BuddySpike.csproj
BUDDY_SPIKE_DLL := backend/tools/BuddySpike/bin/Release/net10.0/FitnessBuddy.BuddySpike.dll

.PHONY: eval-cli eval eval-live eval-schema
eval-cli:
	cd '$(REPO_ROOT)/backend' && '$(DOTNET)' build '$(BUDDY_SPIKE_PROJECT)' -c Release --no-restore -m:1 -nodeReuse:false

eval: eval-cli ## Offline three-case Buddy SDK replay and deterministic parse report (no key)
	cd '$(REPO_ROOT)' && DOTNET='$(DOTNET)' '$(DART)' run tools/buddy_eval/bin/buddy_eval.dart

eval-live: eval-cli ## PAID: at most three fixed synthetic Luna requests; no retries/fallback
	cd '$(REPO_ROOT)' && DOTNET='$(DOTNET)' '$(DART)' run tools/buddy_eval/bin/buddy_eval.dart --live

eval-schema: eval-cli ## Regenerate Buddy's internal schema from C# records
	cd '$(REPO_ROOT)' && '$(DOTNET)' '$(BUDDY_SPIKE_DLL)' --schema > backend/src/Modules/Buddy/Prompts/interpret-v0.schema.json

##@ Private laptop test server (B03)

PHONE_SERVER := python3 '$(REPO_ROOT)/tools/scripts/phone-server.py'
.PHONY: serve-phone-prepare serve-phone-policy serve-phone serve-phone-stop serve-phone-status serve-phone-backup serve-phone-restore-check serve-phone-timer phone-server-check phone-server-smoke
serve-phone-prepare: ## Build an immutable backend image from origin/main and prepare private state outside git
	$(PHONE_SERVER) prepare
serve-phone-policy: ## Generate the private A55-only tailnet policy for owner application
	$(PHONE_SERVER) policy
serve-phone: ## Start the private phone stack (requires confirmed ACL, HTTPS and protected/owner-approved laptop storage)
	$(PHONE_SERVER) up
serve-phone-stop: ## Stop the private phone stack and its owned Serve mapping; preserve data
	$(PHONE_SERVER) stop
serve-phone-status: ## Report phone-server readiness, main revision and backup age
	$(PHONE_SERVER) status
serve-phone-backup: ## Dump the phone database privately; retain seven days after success
	$(PHONE_SERVER) backup
serve-phone-restore-check: ## Restore latest phone backup into an isolated scratch database, then remove the scratch
	$(PHONE_SERVER) restore-check
serve-phone-timer: ## Enable the nightly backup user timer (requires prepared private snapshot)
	$(PHONE_SERVER) install-timer
phone-server-check: ## Offline safety tests for laptop operations, no Tailscale or paid API access
	PYTHONDONTWRITEBYTECODE=1 python3 -I -m unittest discover -s '$(REPO_ROOT)/tools/scripts' -p test_phone_server.py
	bash -n '$(REPO_ROOT)/tools/scripts/setup-tailscale.sh' '$(REPO_ROOT)/infra/phone-server/init-roles.sh'
phone-server-smoke: phone-server-check ## Synthetic Docker isolation/backup/restore/proxy smoke; no phone or Tailscale changes
	@bash '$(REPO_ROOT)/tools/scripts/phone-server-smoke.sh'

.PHONY: gen-sync-schemas check-sync-schemas
gen-sync-schemas: ## Export bounded sync schemas from the contract
	@python3 tools/scripts/export-sync-schemas.py
check-sync-schemas: ## Check embedded sync schemas match the contract
	@python3 tools/scripts/export-sync-schemas.py --check

.PHONY: gen-catalog-schemas check-catalog-schemas catalog-import
gen-catalog-schemas: ## Embed the closed catalog release schemas for backend/Docker
	python3 tools/scripts/gen-catalog-schemas.py
check-catalog-schemas:
	python3 tools/scripts/gen-catalog-schemas.py --check
check-dotnet: check-catalog-schemas
gen: gen-catalog-schemas
catalog-import: ## Import CATALOG_DIR (default build/catalog) using the configured migrate-role credentials and recovery directory
	cd '$(REPO_ROOT)/backend' && '$(DOTNET)' run --project src/Host -c Release -- migrate --Catalog:ImportDirectory="$(abspath $(or $(CATALOG_DIR),build/catalog))"

.PHONY: serve-phone-catalog-import
serve-phone-catalog-import: ## Import the built public catalog into the private laptop stack (migrator only)
	python3 tools/scripts/phone-server.py catalog-import --catalog-dir "$(abspath $(or $(CATALOG_DIR),build/catalog))"

.PHONY: catalog-client-smoke
catalog-client-smoke: ## Offline generated-client check: binary pack bytes survive without UTF8 decoding
	cd '$(REPO_ROOT)/tools/sync_sim' && '$(DART)' test test/catalog_client_test.dart
