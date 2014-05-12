coverageRule = require '../make/coverage'
{expect} = require 'chai'
{
    executeRule
    checkTargets
    RuleDependencyChecker
    CopyRuleChecker
    RuleChecker
    AlwaysTrueChecker
} = require './rule-test-helper'
path = require 'path'

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
        pattern = new RegExp "^.*mocha_istanbul_test_runner.+-p [^\\s]*build/coverage/instrumented -o build/coverage/report/lib/feature #{@tests.join ' '}"
        expect(rule.actions).to.be.a 'string'
        expect(rule.actions).to.match pattern

describe 'coverage rule', ->
    it 'should instrument code', (done) ->
        manifest =
            server:
                scripts:
                    files: ['script1.coffee', 'script2.coffee']

        targets = executeRule coverageRule, {}, manifest

        # direct assertions via expect
        # maybe we can extend the expect syntax to make this more readable?
        expect(targets['instrument']).to.exist
        expect(targets['instrument'].dependencies).to.contain 'lib/feature/instrument'
        expect(targets['lib/feature/instrument'].dependencies).to.contain 'build/coverage/instrumented/lib/feature/script1.js'
        expect(targets['lib/feature/instrument'].dependencies).to.contain 'build/coverage/instrumented/lib/feature/script2.js'

        # old behavior, moved to separate checkTargets method
        checkTargets targets,
            expected:
                'build/coverage/instrumented/lib/feature/script1.js': new InstrumentationRuleChecker 'script1.js'
                'build/coverage/instrumented/lib/feature/script2.js': new InstrumentationRuleChecker 'script2.js'
                #'lib/feature/instrument': new RuleDependencyChecker [
                #    'build/coverage/instrumented/lib/feature/script1.js'
                #    'build/coverage/instrumented/lib/feature/script2.js'
                #]
                #'instrument': new RuleDependencyChecker 'lib/feature/instrument'

        done()

    it 'should copy tests to the instrumented directory', (done) ->
        manifest =
            server:
                test:
                    unit: ['test/unit.coffee']
                    integration: ['test/integration.coffee']

        targets = executeRule coverageRule, {}, manifest
        checkTargets targets,
            expected:
                'build/coverage/instrumented/lib/feature/test/unit.coffee': new CopyRuleChecker 'lib/feature/test/unit.coffee'
                'build/coverage/instrumented/lib/feature/test/integration.coffee': new CopyRuleChecker 'lib/feature/test/integration.coffee'
                'pre_coverage': new RuleDependencyChecker [
                    'build/coverage/instrumented/lib/feature/test/unit.coffee'
                    'build/coverage/instrumented/lib/feature/test/integration.coffee'
                ]

        done()

    it 'should copy assets to the instrumented directory', (done) ->
        manifest =
            server:
                test:
                    assets: ['test/data/asset1.bin', 'test/data/asset2.txt']
                    exports: ['test/helper/export.coffee']

        targets = executeRule coverageRule, {}, manifest
        checkTargets targets,
            expected:
                'build/coverage/instrumented/lib/feature/test/data/asset1.bin': new CopyRuleChecker 'lib/feature/test/data/asset1.bin'
                'build/coverage/instrumented/lib/feature/test/data/asset2.txt': new CopyRuleChecker 'lib/feature/test/data/asset2.txt'
                'build/coverage/instrumented/lib/feature/test/helper/export.coffee': new CopyRuleChecker 'lib/feature/test/helper/export.coffee'
                'pre_coverage': new RuleDependencyChecker [
                    'build/coverage/instrumented/lib/feature/test/data/asset1.bin'
                    'build/coverage/instrumented/lib/feature/test/data/asset2.txt'
                    'build/coverage/instrumented/lib/feature/test/helper/export.coffee'
                ]

        done()

    it 'should create coverage targets', (done) ->
        manifest =
            server:
                test:
                    unit: ['test/unit.coffee']
                    integration: ['test/integration.coffee']

        targets = executeRule coverageRule, {}, manifest
        checkTargets targets,
            expected:
                'lib/feature/coverage': new CoverageRuleChecker [
                    'build/coverage/instrumented/lib/feature/test/unit.coffee'
                    'build/coverage/instrumented/lib/feature/test/integration.coffee'
                ]
                'feature_coverage': new RuleDependencyChecker 'lib/feature/coverage'

        done()

    it 'should add target lib/feature/coverage if no tests are present', (done) ->
        targets = executeRule coverageRule, {}, {}
        checkTargets targets,
            expected:
                'lib/feature/coverage': new AlwaysTrueChecker()
            unexpected:
                'feature_coverage'

        done()
