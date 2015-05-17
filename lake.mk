LAKE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ifndef FEATURES
FEATURES := $(shell cat features)
endif

QUICK_GOALS += %clean clean%
BIG_GOALS := $(strip $(filter-out $(QUICK_GOALS), $(MAKECMDGOALS)))

BUILD ?= build
LAKE_BUILD ?= $(BUILD)/lake
NODE_CLI ?= node

COFFEE_CLI=$(shell $(NODE_CLI) -e 'path = require("path"); p = require.resolve("coffee-script"); while (p && path.basename(path.dirname(p)) != "node_modules") p = path.dirname(p); p = path.join(p, "bin", "coffee"); console.log(p)')
COFFEE ?= $(COFFEE_CLI) --nodejs --harmony

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

clean/npm_tmp:
	rm -rf $(shell npm config get tmp)/npm-* 2> /dev/null || exit 0

.PHONY: npm-shrinkwrap.json clean/node_modules clean/npm_tmp

BUILD_SERVER := $(BUILD)/build-server.d

# TODO: build-server should detach itself, so we do not have to wait arbitrary time before the port is open
$(BUILD_SERVER):
	@touch $@
	@$(COFFEE) $(LAKE_DIR)build-server.coffee "$@" $(BUILD_SERVER_PORT)

.INTERMEDIATE: $(BUILD_SERVER)

-include $(LAKE_BUILD)/rules-created
