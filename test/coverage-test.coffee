coverageRule = require '../coverage'
{
    expect
    Assertion
} = require 'chai'
{executeRule} = require './rule-test-helper'
path = require 'path'

Assertion.addMethod 'instrument', (script) ->
    targets = @_obj._targets.join ' '
    pattern = new RegExp "^.*istanbul.+instrument.+" + targets.replace(/([\^\$\(\)])/g, '\\$1') + ".+" + script + "$", "i"
    new Assertion(@_obj).to.have.a.singleMakeAction pattern

Assertion.addMethod 'cover', (tests) ->
    escaped = tests.map (x) ->
        x.replace(/([\^\$\(\)])/g, '\\$1')
    pattern = new RegExp "^.*mocha_istanbul_test_runner.+-p [^\\s]*\\$\\(BUILD\\)\/coverage/instrumented -o \\$\\(BUILD\\)\/coverage/report/lib/feature #{escaped.join ' '}"
    new Assertion(@_obj).to.have.a.singleMakeAction pattern

describe 'coverage rule', ->
    it 'should instrument code', ->
        manifest =
            server:
                scripts:
                    files: ['script1.coffee', 'script2.coffee']

        targets = executeRule coverageRule, manifest

        expect(targets['instrument']).to.depend 'lib/feature/instrument'
        expect(targets['lib/feature/instrument']).to.depend '$(BUILD)/coverage/instrumented/lib/feature/script1.js'
        expect(targets['lib/feature/instrument']).to.depend '$(BUILD)/coverage/instrumented/lib/feature/script2.js'
        expect(targets['$(BUILD)/coverage/instrumented/lib/feature/script1.js']).to.instrument 'script1.js'
        expect(targets['$(BUILD)/coverage/instrumented/lib/feature/script2.js']).to.instrument 'script2.js'

    it 'should copy tests to the instrumented directory', ->
        manifest =
            server:
                test:
                    unit: ['test/unit.coffee']
                    integration: ['test/integration.coffee']

        targets = executeRule coverageRule, manifest

        expect(targets['pre_coverage']).to.depend '$(BUILD)/coverage/instrumented/lib/feature/test/unit.coffee'
        expect(targets['pre_coverage']).to.depend '$(BUILD)/coverage/instrumented/lib/feature/test/integration.coffee'
        expect(targets['$(BUILD)/coverage/instrumented/lib/feature/test/unit.coffee']).to.copy 'lib/feature/test/unit.coffee'
        expect(targets['$(BUILD)/coverage/instrumented/lib/feature/test/integration.coffee']).to.copy 'lib/feature/test/integration.coffee'

    it 'should copy assets to the instrumented directory', ->
        manifest =
            server:
                test:
                    assets: ['test/data/asset1.bin', 'test/data/asset2.txt']
                    exports: ['test/helper/export.coffee']

        targets = executeRule coverageRule, manifest

        expect(targets['pre_coverage']).to.depend '$(BUILD)/coverage/instrumented/lib/feature/test/data/asset1.bin'
        expect(targets['pre_coverage']).to.depend '$(BUILD)/coverage/instrumented/lib/feature/test/data/asset2.txt'
        expect(targets['pre_coverage']).to.depend '$(BUILD)/coverage/instrumented/lib/feature/test/helper/export.coffee'

        expect(targets['$(BUILD)/coverage/instrumented/lib/feature/test/data/asset1.bin']).to.copy 'lib/feature/test/data/asset1.bin'
        expect(targets['$(BUILD)/coverage/instrumented/lib/feature/test/data/asset2.txt']).to.copy 'lib/feature/test/data/asset2.txt'
        expect(targets['$(BUILD)/coverage/instrumented/lib/feature/test/helper/export.coffee']).to.copy 'lib/feature/test/helper/export.coffee'

    it 'should create coverage targets', ->
        manifest =
            server:
                test:
                    unit: ['test/unit.coffee']
                    integration: ['test/integration.coffee']

        targets = executeRule coverageRule, manifest

        expect(targets['feature_coverage']).to.depend 'lib/feature/coverage'
        expect(targets['lib/feature/coverage']).to.cover [
            '$(BUILD)/coverage/instrumented/lib/feature/test/unit.coffee'
            '$(BUILD)/coverage/instrumented/lib/feature/test/integration.coffee'
        ]

    it 'should add target lib/feature/coverage if no tests are present', ->
        targets = executeRule coverageRule, {}

        expect(targets['lib/feature/coverage']).to.exist
        expect(targets['feature_coverage']).to.not.exist
