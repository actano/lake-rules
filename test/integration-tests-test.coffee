integrationTests = require '../make/integration-tests'
{executeRule} = require './rule-test-helper'
{expect} = require 'chai'

describe 'integration-tests rule', ->
    it 'should create server.test.integration targets', (done) ->
        manifest =
            server:
                test:
                    integration: ['foo-itest.coffee', 'bar-itest.coffee']

        rulesSpy = executeRule integrationTests, {}, manifest

        expect(rulesSpy).to.have.property('lib/feature/integration_test')
        expect(rulesSpy).to.have.property('integration_test')

        expect(rulesSpy).to.have.property('lib/feature/integration_mocha_test')
        expect(rulesSpy['lib/feature/integration_mocha_test'].actions).to.exists
        expect(rulesSpy['lib/feature/integration_mocha_test'].actions).to.have.length 2
        expect(rulesSpy['lib/feature/integration_mocha_test'].actions.join(' ')).to.contain('foo-itest.coffee')
        expect(rulesSpy['lib/feature/integration_mocha_test'].actions.join(' ')).to.contain('bar-itest.coffee')

        done()

    it 'should create integrationTests.casper targets', (done) ->
        manifest =
            integrationTests:
                casper: ['foo-citest.coffee', 'bar-citest.coffee']

        rulesSpy = executeRule integrationTests, {}, manifest

        expect(rulesSpy).to.have.property('lib/feature/integration_test')
        expect(rulesSpy).to.have.property('integration_test')

        expect(rulesSpy).to.have.property('lib/feature/integration_casper_test')
        expect(rulesSpy['lib/feature/integration_casper_test'].actions).to.exists
        expect(rulesSpy['lib/feature/integration_casper_test'].actions).to.have.length 2
        expect(rulesSpy['lib/feature/integration_casper_test'].actions.join(' ')).to.contain('foo-citest.coffee')
        expect(rulesSpy['lib/feature/integration_casper_test'].actions.join(' ')).to.contain('bar-citest.coffee')

        done()
