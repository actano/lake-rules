integrationTests = require '../integration-tests'
{executeRule, globals} = require './rule-test-helper'
{expect} = require 'chai'

describe 'integration-tests rule', ->
    it 'should create server.test.integration targets', ->
        manifest =
            server:
                test:
                    integration: ['foo-itest.coffee', 'bar-itest.coffee']

        targets = executeRule integrationTests, manifest
        localIntegration = manifest._feature 'integration_test'
        localIntegrationMocha = manifest._feature "integration_mocha_test"
        fooIntegration = manifest._feature 'foo-itest'
        barIntegration = manifest._feature 'bar-itest'

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
