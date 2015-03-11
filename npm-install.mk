NPM_INSTALL_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
NODE_MODULES_DEP := node_modules/.package_shasum

ifeq (exists,$(shell test -d node_modules && echo exists))
NEW_SUM := $(firstword $(shell cat node_modules/*/package.json | shasum))
ifneq ($(NEW_SUM),$(shell cat $(NODE_MODULES_DEP) 2> /dev/null))
$(shell echo $(NEW_SUM) > $(NODE_MODULES_DEP))
endif
endif

# flag: NPM_PRODUCTION_DEPENDENCIES_ONLY=1 only include npm production dependencies
ifdef ($(NPM_PRODUCTION_DEPENDENCIES_ONLY),)
	override NPM_FLAGS += --production
endif

CLEAN_NPM_TMP = rm -rf "$(shell npm config get tmp)/npm-*" 2> /dev/null || exit 0

node_modules: $(NODE_MODULES_DEP)

$(NODE_MODULES_DEP): package.json
	npm install $(NPM_FLAGS)
	@cat node_modules/*/package.json | shasum > $@
	@$(CLEAN_NPM_TMP)

npm-shrinkwrap.json: node_modules
	npm prune
	npm shrinkwrap --dev
	$(shell npm bin)/coffee $(NPM_INSTALL_DIR)fix-shrinkwrap.coffee $@
	@touch -r $(NODE_MODULES_DEP) $@

clean: clean/node_modules

clean/node_modules:
	rm -rf node_modules

clean/npm_tmp:
	$(CLEAN_NPM_TMP)

.PHONY: clean clean/node_modules clean/npm_tmp

