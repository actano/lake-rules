LAKE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ifndef FEATURES
FEATURES := $(shell cat features)
endif

export FAIL_FAST ?= 0
QUICK_GOALS += %clean clean% npm-shrinkwrap.json
BIG_GOALS := $(strip $(filter-out $(QUICK_GOALS), $(MAKECMDGOALS)))

BUILD ?= build
LAKE_BUILD ?= $(BUILD)/lake
NODE_CLI ?= node
NODE_FLAGS ?= --harmony-generators

COFFEE_CLI := $(shell $(NODE_CLI) -e 'console.log(require.resolve("coffee-script/bin/coffee"));')
MOCHA_CLI := $(shell $(NODE_CLI) -e 'console.log(require.resolve("mocha/bin/mocha"));')
COFFEE ?= $(COFFEE_CLI) --nodejs $(NODE_FLAGS)
MOCHA_RUNNER := $(MOCHA_CLI) $(NODE_FLAGS) --compilers coffee:coffee-script/register
INTEGRATION_RUNNER = $(MOCHA_RUNNER)

export TEST_REPORTS ?= $(BUILD)/reports
export KARMA_BROWSERS ?= Chrome
export KARMA_LOG_LEVEL ?= INFO

# ms to wait after test-run for browser-errors during test-cleanup (<0 to run in nextTick)
export KARMA_WAIT_MS ?= 10

# Add 'touch node_modules/.install.d' to your postinstall script, to use auto-npm-install
LAKE_INSTALL_D_EXIST:=$(shell test -f node_modules/.install.d && touch -r npm-shrinkwrap.json node_modules/.shrinkwrap.d && echo exist)

BUILD_SERVER_PORT ?= 8124

# target: manifest_consistency_check - consistency test for manifest, p.e. remote component versions
manifest_consistency_check:
	$(COFFEE) $(LAKE_DIR)/manifest-consistency-check.coffee lake.config.coffee

.PHONY: manifest_consistency_check

# Lake Rules related

# Generate a make include via lake.
# We start lake only once to make it fast.
ifneq (,$(BIG_GOALS))
$(LAKE_BUILD)/rules-created: $(FEATURES:%=%/Manifest.coffee) lake.config.coffee features $(LAKE_DIR)
	@mkdir -p $(LAKE_BUILD) && \
	$(COFFEE) $(LAKE_DIR)/lake/lake-create-mk.coffee $(FEATURES:%=-i %) -o $(LAKE_BUILD) > $(LAKE_BUILD)/rules-created.tmp
	@mv -f $(LAKE_BUILD)/rules-created.tmp $@
endif

$(FEATURES:%=%/Manifest.coffee):
	$(error $@ is missing)

feature_clean: $(FEATURES:%=%/clean)
.PHONY: feature_clean

$(FEATURES:%=%/clean):
# $(@D) is a bit of a hack, as the target isn't a real path but we need
# everyhting except /clean so this works out nicely :-)
	rm -rf $(RUNTIME)/$(@D)
	rm -rf $(SERVER)/$(@D)
	rm -rf $(LOCAL_COMPONENTS)/$(@D)

lake: $(LAKE_BUILD)/rules-created

lake/clean:
	rm -rf $(LAKE_BUILD)

.PHONY: lake lake/clean $(FEATURES) $(FEATURES:%=%/clean)

# target: help/lake - show lake help-topics
help/lake:
	@echo "Available topics are:"
	@$(COFFEE) $(LAKE_DIR)/lake/lake-help.coffee topics
	@echo "\nRun 'make help/[topic]' to show additional information about a specific topic."

help/%:
	@$(COFFEE) $(LAKE_DIR)/lake/lake-help.coffee $* | less -FX

npm-shrinkwrap.json:
	npm prune
	npm shrinkwrap --dev
	$(COFFEE) $(LAKE_DIR)/fix-shrinkwrap.coffee $@
ifeq ($(LAKE_INSTALL_D_EXIST),exist)
	@touch node_modules/.install.d

node_modules/.install.d: node_modules/.shrinkwrap.d
	npm install
	rm -rf $(shell npm config get tmp)/npm-* 2> /dev/null || exit 0

build: node_modules/.install.d
endif

clean/npm_tmp:
	rm -rf $(shell npm config get tmp)/npm-* 2> /dev/null || exit 0

.PHONY: npm-shrinkwrap.json clean/node_modules clean/npm_tmp

BUILD_SERVER := $(BUILD)/build-server.d

$(BUILD_SERVER):
	@touch $@
	@$(COFFEE) $(LAKE_DIR)build-server.coffee "$@" $(BUILD_SERVER_PORT)

.INTERMEDIATE: $(BUILD_SERVER)

-include $(LAKE_BUILD)/rules-created
