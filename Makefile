TESTS := \
	coverage \
	integration-tests \
	translations \
	browser-tests \
	rest-api \
	database \
	component \
	component-build \
	htdocs \
	webapp \
	menu

NODE_MODULES := $(shell npm bin)
TEST_TARGETS := $(TESTS:%=report/%.xml)
ifndef REPORTER
	REPORTER := sternchen
endif

ifdef DEBUG_BRK
	DEBUG_BRK := --debug-brk
endif

NPM_TMP_DIR:=$(abspath npm_tmp)

all: test

$(TESTS): node_modules | report
	PREFIX=report REPORT_FILE=$@.xml $(NODE_MODULES)/mocha $(DEBUG_BRK) -R $(REPORTER) --compilers coffee:coffee-script,coffee-trc:coffee-errors test/$@-test.coffee

test: node_modules | report
	PREFIX=report REPORT_FILE=report.xml $(NODE_MODULES)/mocha $(DEBUG_BRK) -R $(REPORTER) --compilers coffee:coffee-script,coffee-trc:coffee-errors $(TESTS:%=test/%-test.coffee)

watch:
	$(NODE_MODULES)/mocha --watch -R min --compilers coffee:coffee-script,coffee-trc:coffee-errors $(TESTS:%=test/%-test.coffee)

.PHONY: $(TESTS)

# TODO: 'coverage has to run on all suites' vs. 'test reports can only be generated for single test suites'
#report/%.xml: node_modules instrumented/%.js instrumented/helper instrumented/test/%-test.js \
#instrumented/test/mocha-runner.js instrumented/test/rule-test-helper.js | report coverage
#	PREFIX=report REPORT_FILE=$*.xml node instrumented/test/mocha-runner.js instrumented/test/$*-test.js

#report instrumented/make instrumented/test uninstrumented coverage:
report:
	mkdir -p $@

#instrumented/test/%.js: %.coffee node_modules | instrumented/test
#	$(NODE_MODULES)/coffee -o $(@D) -c $<

#instrumented/helper: node_modules ../helper/*.coffee
#	mkdir -p instrumented/helper
#	$(NODE_MODULES)/coffee -o instrumented/helper -c ../helper
#	touch $@

#instrumented/%.js: ../%.coffee node_modules | uninstrumented instrumented/make
#	$(NODE_MODULES)/coffee -o uninstrumented -c $<
#	$(NODE_MODULES)/istanbul instrument --no-compact --output $@ uninstrumented/$*.js


clean: | clean_npm_tmp
	rm -rf report
#	rm -rf instrumented
#	rm -rf uninstrumented
#	rm -rf coverage

node_modules: package.json | clean_npm_tmp
	npm prune
	npm install --tmp="$(NPM_TMP_DIR)"
	touch node_modules

clean_npm_tmp:
	rm -rf "$(NPM_TMP_DIR)"

.PHONY: ruletest clean clean_npm_tmp
