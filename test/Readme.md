# Lake rule tests

## How to add a new test suite

To add a new test suite for the rule file `tools/rules/make/rule.coffee` one needs to add a file with the same basename
as the rule file prefixed with '-test', i.e. `tools/rules/test/rule-test.coffee`. Additionally the basename of the rule
file has to be appended to the `TESTS` variable in the Makefile.

## How to write tests

[TODO]