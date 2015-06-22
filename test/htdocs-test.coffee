# external dep
{expect} = require 'chai'

# local dep
{executeRule, globals} = require './rule-test-helper'

# rule dep
htdocs = require '../htdocs'

describe 'htdocs rule', ->
    it 'should create a client.htdocs target', (done) ->
        manifest =
            client:
                htdocs:
                    html: 'foo.jade'
                    dependencies: ['../view/bar.jade']

        targets = executeRule htdocs, manifest

        expect(targets).to.have.property(manifest._feature "htdocs")
        expect(targets).to.have.property('htdocs')
        expect(targets).to.have.property(manifest._build "foo.html")

        expect(targets[manifest._build "foo.html"]._prerequisites).to.match(/component-build/)
        expect(targets[manifest._build "foo.html"]._prerequisites).to.match(/bar.jade/)

        done()

