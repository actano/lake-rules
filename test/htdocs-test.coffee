# external dep
{expect} = require 'chai'

# local dep
{executeRule, globals} = require './rule-test-helper'

# rule dep
htdocs = require '../make/htdocs'

_feature = (dst) -> "#{globals.featurePath}/#{dst}"
_build = (script) ->  "#{globals.lake.featureBuildDirectory}/#{globals.featurePath}/#{script}"

describe 'htdocs rule', ->
    it 'should create a client.htdocs target', (done) ->
        manifest =
            client:
                htdocs:
                    html: 'foo.jade'
                    dependencies: ['../view/bar.jade']

        targets = executeRule htdocs, {}, manifest

        expect(targets).to.have.property(_feature "htdocs")
        expect(targets).to.have.property('htdocs')
        expect(targets).to.have.property(_build "foo.html")

        expect(targets[_build "foo.html"].dependencies).to.match(/component-build/)
        expect(targets[_build "foo.html"].dependencies).to.match(/bar.jade/)

        done()

