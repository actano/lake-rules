TESTS := \
	coverage

TEST_TARGETS := $(TESTS:%=report/%.xml)

ruletest: $(TEST_TARGETS)

report/%.xml: ../make/%.coffee %-test.coffee instrumented | report coverage
	coffee -o instrumented/test -c $*-test.coffee
	PREFIX=report REPORT_FILE=$*.xml node instrumented/test/mocha-runner.js instrumented/test/$*-test.js

report instrumented/make instrumented/test uninstrumented coverage:
	mkdir -p $@

instrumented/test/%.js: %.coffee | instrumented/test
	coffee -o $(@D) -c $<

instrumented/helper: ../helper/*.coffee
	mkdir -p instrumented/helper
	coffee -o instrumented/helper -c ../helper
	touch $@

instrumented: instrumented/helper instrumented/test/mocha-runner.js instrumented/test/rule-test-helper.js | instrumented/make uninstrumented
	coffee -o uninstrumented -c ../make
	istanbul instrument --no-compact --output instrumented/make uninstrumented
	touch instrumented

clean:
	rm -rf report
	rm -rf instrumented
	rm -rf uninstrumented
	rm -rf coverage

.PHONY: ruletest clean
