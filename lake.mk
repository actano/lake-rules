LAKE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ifndef COFFEE
NODE_BIN := $(shell npm bin)
COFFEE := $(NODE_BIN)/coffee --nodejs --harmony
endif

# target: manifest_consistency_check - consistency test for manifest, p.e. remote component versions
manifest_consistency_check:
	$(COFFEE) $(LAKE_DIR)/manifest-consistency-check.coffee lake.config.coffee

.PHONY: manifest_consistency_check
