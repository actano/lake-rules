LAKE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ifndef FEATURES
FEATURES := $(shell cat features)
endif

BUILD ?= build
LAKE_BUILD ?= $(BUILD)/lake

# target: manifest_consistency_check - consistency test for manifest, p.e. remote component versions
manifest_consistency_check:
	$(COFFEE) $(LAKE_DIR)/manifest-consistency-check.coffee lake.config.coffee

.PHONY: manifest_consistency_check

# Lake Rules related

LAKE_MK_FILES := $(FEATURES:lib/%=$(LAKE_BUILD)/%.mk)
$(LAKE_MK_FILES): $(LAKE_BUILD)/rules-created

-include $(LAKE_BUILD)/rules-created
-include $(LAKE_MK_FILES)

# Generate a make include via lake.
# We start lake only once to make it fast.
$(LAKE_BUILD)/rules-created: $(FEATURES:%=%/Manifest.coffee) lake.config.coffee features $(LAKE_DIR)
	@mkdir -p $(LAKE_BUILD) && \
	$(COFFEE) $(LAKE_DIR)/lake/lake-create-mk.coffee $(FEATURES:%=-i %) -o $(LAKE_BUILD)
	@touch $@

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

