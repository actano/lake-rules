LAKE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ifndef COFFEE
COFFEE := $(shell npm bin)/coffee --nodejs --harmony
endif
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
$(LAKE_BUILD)/rules-created: node_modules $(FEATURES:%=%/Manifest.coffee) lake.config.coffee features
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

lake/clean:
	rm -rf $(LAKE_BUILD)

.PHONY: lake/clean $(FEATURES) $(FEATURES:%=%/clean)
