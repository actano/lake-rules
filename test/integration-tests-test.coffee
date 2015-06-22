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

        localIntegration = _feature 'integration_test'
        localIntegrationMocha = _feature "integration_mocha_test"
        fooIntegration = _feature 'foo-itest'
        barIntegration = _feature 'bar-itest'

        targets = executeRule integrationTests, {}, manifest
        expect targets['integration_test']
            .to.depend localIntegration
        expect targets[localIntegration]
            .to.depend localIntegrationMocha
        expect targets[localIntegrationMocha]
            .to.depend fooIntegration
        expect targets[localIntegrationMocha]
            .to.depend barIntegration
        expect targets[fooIntegration]
            .to.have.makeActions [/foo-itest.coffee/]
        expect targets[barIntegration]
            .to.have.makeActions [/bar-itest.coffee/]
