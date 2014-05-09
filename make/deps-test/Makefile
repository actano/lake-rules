ROOT := $(abspath ../../../..)
NODE_BIN := $(ROOT)/node_modules/.bin
TOOLS := $(ROOT)/tools

BUILD_DIR := $(abspath build)
DEPS_DIR := $(BUILD_DIR)

VPATH = $(DEPS_DIR):$(abspath .)
COFFEE := $(NODE_BIN)/coffee
JADE_DEPS := $(COFFEE) $(TOOLS)/rules/make/create-jade-dependencies.coffee
JADE := $(NODE_BIN)/jade

all: outer.html

clean:
	rm -rf build

.PHONY: all clean

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.jade.dependencies: $(BUILD_DIR)/%.jade.includes %.jade
	touch "$@"

$(BUILD_DIR)/%.jade.includes: %.jade | $(BUILD_DIR)
	$(JADE_DEPS) --dir "\$$(BUILD_DIR)/" "$*.jade" > "$@"

# File Specific

ifneq ($(MAKECMDGOALS),clean)
-include $(BUILD_DIR)/outer.jade.includes
endif

outer.html: outer.jade $(BUILD_DIR)/outer.jade.dependencies
	$(JADE) "$<" --out "$(BUILD_DIR)/$(@D)"

