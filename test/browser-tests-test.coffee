browserTestsRule = require '../browser-tests'
{expect, Assertion} = require 'chai'
{executeRule, globals} = require './rule-test-helper'
path = require 'path'

Assertion.addMethod 'jadeHtmlRule', (tests) ->
    pattern = new RegExp "jade\\.html.+\\$@.+\\$<.+\\{.*tests.*:.*#{tests.join ' '}.*\\}"
    new Assertion(@_obj).to.have.a.singleMakeAction pattern

_local = (file) -> path.join globals.featurePath, file
_build = (file) -> path.join globals.featureBuildDirectory, globals.featurePath, file

describe 'browser tests rule', ->
    # TODO add tests for karma
    it 'should create a test.html and run tests', ->
        manifest =
            name: 'feature'
            client:
                tests:
                    browser:
                        scripts: ['test/test1.coffee', 'test/test2.coffee']
                        html: 'views/test.jade'

        targets = executeRule browserTestsRule, {}, manifest

        # create test.html
        expect(targets[_build 'test/test1.js']).to.depend _local 'test/test1.coffee'
        expect(targets[_build 'test/test2.js']).to.depend _local 'test/test2.coffee'
        expect(targets[_build 'test/test.html']).to.depend [_build('test/test1.js'), _build('test/test2.js')]
        expect(targets[_build 'test/test.html']).to.be.a.jadeHtmlRule ['test1.js', 'test2.js']

        # run tests
        expect(targets).to.have.phonyTarget _local 'client_test'
        expect(targets[_local 'client_test']).to.depend _build 'test/test.html'

        expect(targets[_local 'client_test']).to.useBuildServer 'casper', null, null, _local 'browser-test.xml'

        expect(targets).to.have.phonyTarget _local 'test'
        expect(targets[_local 'test']).to.depend _local 'client_test'

        expect(targets['client_test']).to.depend _local 'client_test'

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
