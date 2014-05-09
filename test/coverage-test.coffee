coverageRule = require '../make/coverage'
{expect} = require 'chai'
{
    checkRule
    RuleDependencyChecker
    CopyRuleChecker
    RuleChecker
    AlwaysTrueChecker
} = require './rule-test-helper'
path = require 'path'

_lake =
    coveragePath: 'testPath/coverage'

class InstrumentationRuleChecker extends RuleChecker
    constructor: (@input) ->
        super "instrumentation of #{@input}"

    checkRule: (rule) ->
        pattern = new RegExp "^.*istanbul.+instrument.+" + rule.targets + ".+" + @input + "$", "i"
        expect(rule.actions).to.be.a 'string'
        expect(rule.actions).to.match pattern

class CoverageRuleChecker extends RuleChecker
    constructor: (@tests) ->
        super "coverage of #{@tests}"

    checkRule: (rule) ->
        pattern = new RegExp "^.*mocha_istanbul_test_runner.+-p .*?testPath/coverage/instrumented -o testPath/coverage/report/lib/feature #{@tests.join ' '}"
        expect(rule.actions).to.be.a 'string'
        expect(rule.actions).to.match pattern

describe 'coverage rule', ->
    it 'should instrument code', (done) ->
        manifest =
            server:
                scripts:
                    files: ['script1.coffee', 'script2.coffee']

        checkRule coverageRule, _lake, manifest,
            expected:
                'testPath/coverage/instrumented/lib/feature/script1.js': new InstrumentationRuleChecker 'script1.js'
                'testPath/coverage/instrumented/lib/feature/script2.js': new InstrumentationRuleChecker 'script2.js'
                'lib/feature/instrument': new RuleDependencyChecker [
                    'testPath/coverage/instrumented/lib/feature/script1.js'
                    'testPath/coverage/instrumented/lib/feature/script2.js'
                ]
                'instrument': new RuleDependencyChecker 'lib/feature/instrument'

        done()

    it 'should copy tests to the instrumented directory', (done) ->
        manifest =
            server:
                test:
                    unit: ['test/unit.coffee']
                    integration: ['test/integration.coffee']

        checkRule coverageRule, _lake, manifest,
            expected:
                'testPath/coverage/instrumented/lib/feature/test/unit.coffee': new CopyRuleChecker 'lib/feature/test/unit.coffee'
                'testPath/coverage/instrumented/lib/feature/test/integration.coffee': new CopyRuleChecker 'lib/feature/test/integration.coffee'
                'pre_coverage': new RuleDependencyChecker [
                    'testPath/coverage/instrumented/lib/feature/test/unit.coffee'
                    'testPath/coverage/instrumented/lib/feature/test/integration.coffee'
                ]

        done()

    it 'should copy assets to the instrumented directory', (done) ->
        manifest =
            server:
                test:
                    assets: ['test/data/asset1.bin', 'test/data/asset2.txt']
                    exports: ['test/helper/export.coffee']

        checkRule coverageRule, _lake, manifest,
            expected:
                'testPath/coverage/instrumented/lib/feature/test/data/asset1.bin': new CopyRuleChecker 'lib/feature/test/data/asset1.bin'
                'testPath/coverage/instrumented/lib/feature/test/data/asset2.txt': new CopyRuleChecker 'lib/feature/test/data/asset2.txt'
                'testPath/coverage/instrumented/lib/feature/test/helper/export.coffee': new CopyRuleChecker 'lib/feature/test/helper/export.coffee'
                'pre_coverage': new RuleDependencyChecker [
                    'testPath/coverage/instrumented/lib/feature/test/data/asset1.bin'
                    'testPath/coverage/instrumented/lib/feature/test/data/asset2.txt'
                    'testPath/coverage/instrumented/lib/feature/test/helper/export.coffee'
                ]

        done()

    it 'should create coverage targets', (done) ->
        manifest =
            server:
                test:
                    unit: ['test/unit.coffee']
                    integration: ['test/integration.coffee']

        checkRule coverageRule, _lake, manifest,
            expected:
                'lib/feature/coverage': new CoverageRuleChecker [
                    'testPath/coverage/instrumented/lib/feature/test/unit.coffee'
                    'testPath/coverage/instrumented/lib/feature/test/integration.coffee'
                ]

        done()

    it 'should add target lib/feature/coverage if no tests are present', (done) ->
        checkRule coverageRule, _lake, {},
            expected:
                'lib/feature/coverage': new AlwaysTrueChecker()

        done()
