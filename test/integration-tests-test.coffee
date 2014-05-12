integrationTests = require '../make/integration-tests'
{executeRule, globals} = require './rule-test-helper'
{expect} = require 'chai'

_feature = (dst) -> "#{globals.featurePath}/#{dst}"

describe 'integration-tests rule', ->
    it 'should create server.test.integration targets', (done) ->
        manifest =
            server:
                test:
                    integration: ['foo-itest.coffee', 'bar-itest.coffee']

        targets = executeRule integrationTests, {}, manifest
        expect(targets).to.have.property(_feature "integration_test")
        expect(targets).to.have.property('integration_test')

        expect(targets).to.have.property(_feature "integration_mocha_test")
        expect(targets[_feature "integration_mocha_test"].actions).to.exists
        expect(targets[_feature "integration_mocha_test"].actions).to.have.length 2
        expect(targets[_feature "integration_mocha_test"].actions).to.match(/foo-itest.coffee/)
        expect(targets[_feature "integration_mocha_test"].actions).to.match(/bar-itest.coffee/)

        done()

    it 'should create integrationTests.casper targets', (done) ->
        manifest =
            integrationTests:
                casper: ['foo-citest.coffee', 'bar-citest.coffee']

        targets = executeRule integrationTests, {}, manifest

        expect(targets).to.have.property(_feature "integration_test")
        expect(targets).to.have.property('integration_test')

        expect(targets).to.have.property(_feature "integration_casper_test")
        expect(targets[_feature "integration_casper_test"].actions).to.exists
        expect(targets[_feature "integration_casper_test"].actions).to.have.length 2
        expect(targets[_feature "integration_casper_test"].actions).to.match(/foo-citest.coffee/)
        expect(targets[_feature "integration_casper_test"].actions).to.match(/bar-citest.coffee/)

        done()
