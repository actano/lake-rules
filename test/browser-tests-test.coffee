browserTestsRule = require '../browser-tests'
{expect, Assertion} = require 'chai'
{executeRule, globals} = require './rule-test-helper'
path = require 'path'

Assertion.addMethod 'jadeHtmlRule', (tests) ->
    pattern = new RegExp "jade\\.html.+\\$@.+\\$<.+\\{.*tests.*:.*#{tests.join ' '}.*\\}"
    new Assertion(@_obj).to.have.a.singleMakeAction pattern

describe 'browser tests rule', ->
    # TODO add tests for karma
    it 'should run tests', ->
        manifest =
            name: 'feature'
            client:
                tests:
                    browser:
                        scripts: ['test/test1.coffee', 'test/test2.coffee']
                        html: 'views/test.jade'

        targets = executeRule browserTestsRule, {}, manifest

        # create test.html
        expect targets
            .to.have.property manifest._build 'test/test1.js'
        expect targets
            .to.have.property manifest._build 'test/test2.js'
        expect(targets[manifest._build 'test/test1.js']).to.depend manifest._local 'test/test1.coffee'
        expect(targets[manifest._build 'test/test2.js']).to.depend manifest._local 'test/test2.coffee'

        # run tests
        expect(targets).to.have.phonyTarget manifest._local 'client_test'

        expect(targets).to.have.phonyTarget manifest._local 'test'
        expect(targets[manifest._local 'test']).to.depend manifest._local 'client_test'

        expect(targets['client_test']).to.depend manifest._local 'client_test'

    it 'should not generate tests when no browser tests are given', ->
        manifest =
            name: 'feature'
            client:
                tests: {}

        targets = executeRule browserTestsRule, {}, manifest
        expect(targets).to.be.empty

    it 'should not generate tests when no browser tests are empty', ->
        manifest =
            name: 'feature'
            client:
                tests:
                    browser: {}

        targets = executeRule browserTestsRule, {}, manifest
        expect(targets).to.be.empty


    # TODO fix the rule to make this green!
    it.skip 'should fail when test html is given but tests is empty', ->
        manifest =
            name: 'feature'
            client:
                tests:
                    browser:
                        html: 'views/test.jade'
                        scripts: []

        expect(-> executeRule browserTestsRule, {}, manifest).to.throw()

    # TODO fix the rule to make this green!
    it.skip 'should fail when test html is given but tests is undefined', ->
        manifest =
            name: 'feature'
            client:
                tests:
                    browser:
                        html: 'views/test.jade'

        expect(-> executeRule browserTestsRule, {}, manifest).to.throw()

    # TODO fix the rule to make this green!
    it.skip 'should fail when scripts are given but html is undefined', ->
        manifest =
            name: 'feature'
            client:
                tests:
                    browser:
                        scripts: ['test/test1.coffee', 'test/test2.coffee']

        expect(-> executeRule browserTestsRule, {}, manifest).to.throw()

    # TODO fix the rule to make this green!
    it.skip 'should fail when scripts contains an empty string', ->
        manifest =
            name: 'feature'
            client:
                tests:
                    browser:
                        scripts: ['test/test1.coffee', '', 'test/test2.coffee']
                        html: 'views/test.jade'

        expect(-> executeRule browserTestsRule, {}, manifest).to.throw()

    # TODO fix the rule to make this green!
    it.skip 'should fail when html is an empty string', ->
        manifest =
            name: 'feature'
            client:
                tests:
                    browser:
                        scripts: ['test/test1.coffee', 'test/test2.coffee']
                        html: ''

        expect(-> executeRule(browserTestsRule, {}, manifest)).to.throw()
