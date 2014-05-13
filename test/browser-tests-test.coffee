browserTestsRule = require '../make/browser-tests'
{expect, Assertion} = require 'chai'
{
    executeRule
} = require './rule-test-helper'
path = require 'path'

Assertion.addMethod 'jadeHtmlRule', (tests) ->
    pattern = new RegExp "jade-require.+\\$<.+\\$@.+--obj '\\{.*\"tests\":\"#{tests.join ' '}\".*\\}"
    new Assertion(@_obj).to.have.a.singleMakeAction pattern

_local = (file) -> path.join 'lib/feature', file
_build = (file) -> path.join 'build/local_components/lib/feature', file

describe 'browser tests rule', ->
    it 'should create a test.html and run tests', (done) ->
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

        pattern = new RegExp "casperjs.+#{_build 'test/test.html'}", "i"
        expect(targets[_local 'client_test']).to.have.makeActions [pattern]

        expect(targets).to.have.phonyTarget _local 'test'
        expect(targets[_local 'test']).to.depend _local 'client_test'

        expect(targets['client_test']).to.depend _local 'client_test'

        done()
