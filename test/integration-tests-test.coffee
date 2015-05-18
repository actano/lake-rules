integrationTests = require '../integration-tests'
{executeRule, globals} = require './rule-test-helper'
{expect} = require 'chai'

_feature = (dst) -> "#{globals.featurePath}/#{dst}"

describe 'integration-tests rule', ->
    it 'should create server.test.integration targets', ->
        manifest =
            server:
                test:
                    integration: ['foo-itest.coffee', 'bar-itest.coffee']

        targets = executeRule integrationTests, {}, manifest
        expect(targets).to.have.property(_feature "integration_test")
        expect(targets).to.have.property('integration_test')

        expect(targets).to.have.property(_feature "integration_mocha_test")
        expect(targets[_feature "integration_mocha_test"]).to.have.makeActions [
            /foo-itest.coffee/
            /bar-itest.coffee/
        ]
