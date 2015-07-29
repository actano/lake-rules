restApiRule = require '../rest-api'
{executeRule} = require './rule-test-helper'
{config} = require '../lake/config'
{expect} = require 'chai'
path = require 'path'

_runtime = (file) -> path.join config.runtimePath, file
_absolute = (file) -> path.join config.root, file

describe 'rest-api rule', ->
    it 'should declare test as phony', ->
        manifest = server: {}

        targets = executeRule restApiRule, manifest
        expect(targets).to.have.phonyTarget 'lib/feature/unit_test'

    it 'should run unit tests', ->
        manifest =
            server:
                test:
                    unit: ['test/unitA.coffee', 'test/unitB.coffee']
        targets = executeRule restApiRule, manifest
        unitTest = targets['lib/feature/unit_test']
        expect unitTest
            .to.depend 'lib/feature/test/unitA'
        expect unitTest
            .to.depend 'lib/feature/test/unitB'

        expect targets['lib/feature/test/unitA']
            .to.have.makeActions [/\$\(MOCHA_RUNNER\) .*test\/unitA\.coffee/]

        expect targets['lib/feature/test/unitB']
            .to.have.makeActions [/\$\(MOCHA_RUNNER\) .*test\/unitB\.coffee/]

    it.skip 'should pass the current target to mocha', ->
        manifest =
            server:
                test:
                    unit: ['test/unitA.coffee']
        targets = executeRule restApiRule, manifest
        unitTest = targets['lib/feature/unit_test']
        expect(unitTest.actions[0]).to.match /MAKE_TARGET=lib\/feature\/unit_test/

    it 'should add unit tests to the local test target', ->
        manifest =
            server:
                test:
                    unit: ['test/unit.coffee']

        targets = executeRule restApiRule, manifest
        expect(targets['lib/feature/test']).to.depend 'lib/feature/unit_test'
