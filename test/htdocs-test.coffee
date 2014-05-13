# external dep
{expect} = require 'chai'

# local dep
{executeRule, globals} = require './rule-test-helper'

# rule dep
htdocs = require '../make/htdocs'

_feature = (dst) -> "#{globals.featurePath}/#{dst}"
_build = (script) ->  "#{globals.lake.featureBuildDirectory}/#{globals.featurePath}/#{script}"

describe 'htdocs rule', ->
    it 'should create server.test.integration targets', (done) ->
        manifest =
            client:
                htdocs:
                    html: 'foo.jade'
                    dependencies: []

        targets = executeRule htdocs, {}, manifest
        expect(targets).to.have.property(_feature "htdocs")
        expect(targets).to.have.property('htdocs')
        expect(targets).to.have.property(_build "foo.html")

        done()

