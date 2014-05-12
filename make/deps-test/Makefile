ROOT := $(abspath ../../../..)
NODE_BIN := $(ROOT)/node_modules/.bin
TOOLS := $(ROOT)/tools

BUILD_DIR := $(abspath build)
DEPS_DIR := $(BUILD_DIR)

VPATH = $(DEPS_DIR):$(abspath .)
COFFEE := $(NODE_BIN)/coffee
JADE_DEPS := $(COFFEE) $(TOOLS)/rules/make/create-jade-dependencies.coffee
JADE := $(NODE_BIN)/jade

all: $(BUILD_DIR)/outer.html

clean:
	rm -rf build

.PHONY: all clean

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.jade.dependencies: $(BUILD_DIR)/%.jade.includes %.jade | $(BUILD_DIR)
	@touch "$@"

$(BUILD_DIR)/%.jade.includes: %.jade | $(BUILD_DIR)
	$(JADE_DEPS) --dir "\$$(BUILD_DIR)/" "$*.jade" --out "$(BUILD_DIR)"

$(BUILD_DIR)/%.html: %.jade $(BUILD_DIR)/%.jade.dependencies
	$(JADE) "$<" --out "$(@D)"

.PRECIOUS: $(BUILD_DIR)/%.jade.dependencies $(BUILD_DIR)/%.jade.includes

# File Specific

-include $(BUILD_DIR)/outer.jade.includes*

