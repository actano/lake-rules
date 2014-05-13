TESTS := \
	coverage \
	integration-tests \
	translations \
	browser-tests

NODE_MODULES := $(shell npm bin)

TEST_TARGETS := $(TESTS:%=report/%.xml)

ruletest: $(TEST_TARGETS)

report/%.xml: %-test.coffee ../make/%.coffee node_modules | report
	PREFIX=report REPORT_FILE=$*.xml $(NODE_MODULES)/mocha -R sternchen --compilers coffee:coffee-script,coffee-trc:coffee-errors $<

# TODO: 'coverage has to run on all suites' vs. 'test reports can only be generated for single test suites'
#report/%.xml: node_modules instrumented/make/%.js instrumented/helper instrumented/test/%-test.js \
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

#instrumented/make/%.js: ../make/%.coffee node_modules | uninstrumented instrumented/make
#	$(NODE_MODULES)/coffee -o uninstrumented -c $<
#	$(NODE_MODULES)/istanbul instrument --no-compact --output $@ uninstrumented/$*.js


clean:
	rm -rf report
#	rm -rf instrumented
#	rm -rf uninstrumented
#	rm -rf coverage

node_modules: package.json
	npm prune
	npm install

.PHONY: ruletest clean

# don't delete intermediate files
.SECONDARY:
