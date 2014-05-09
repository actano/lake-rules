coverageRule = require '../make/coverage'
{expect} = require 'chai'
{
    checkRule
    RuleDependencyChecker
    CopyRuleChecker
    RuleChecker
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

describe 'coverage rule', ->
    it 'should instrument code', (done) ->
        manifest =
            server:
                scripts:
                    files: ['script1.coffee', 'script2.coffee']

        expects =
            'testPath/coverage/instrumented/lib/feature/script1.js': new InstrumentationRuleChecker 'script1.js'
            'testPath/coverage/instrumented/lib/feature/script2.js': new InstrumentationRuleChecker 'script2.js'
            'lib/feature/instrument': new RuleDependencyChecker [
                'testPath/coverage/instrumented/lib/feature/script1.js'
                'testPath/coverage/instrumented/lib/feature/script2.js'
            ]
            'instrument': new RuleDependencyChecker 'lib/feature/instrument'

        checkRule coverageRule, _lake, manifest, expects

        done()

    it 'should copy tests to the instrumented directory', (done) ->
        manifest =
            server:
                test:
                    unit: ['test/unit.coffee']
                    integration: ['test/integration.coffee']
                    assets: ['test/data/asset1.bin', 'test/data/asset2.txt']
                    exports: ['test/helper/export.coffee']

        expects =
            'testPath/coverage/instrumented/lib/feature/test/unit.coffee': new CopyRuleChecker 'lib/feature/test/unit.coffee'
            'testPath/coverage/instrumented/lib/feature/test/integration.coffee': new CopyRuleChecker 'lib/feature/test/integration.coffee'
            'pre_coverage': new RuleDependencyChecker [
                'testPath/coverage/instrumented/lib/feature/test/unit.coffee'
                'testPath/coverage/instrumented/lib/feature/test/integration.coffee'
            ]

        checkRule coverageRule, _lake, manifest, expects

        done()
