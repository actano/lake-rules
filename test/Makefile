NODE_BIN := $(shell npm bin)

TESTS := \
	coverage-test

TEST_TARGETS := $(TESTS:%=report/%.xml)

ruletest: $(TEST_TARGETS)

report:
	mkdir -p $@

report/%.xml: %.coffee | report
	PREFIX=report REPORT_FILE=$*.xml $(NODE_BIN)/mocha -R sternchen --compilers coffee:coffee-script,coffee-trc:coffee-errors $<

clean:
	rm -rf report

.PHONY: ruletest clean
