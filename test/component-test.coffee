# external dep
{expect} = require 'chai'

# local dep
{executeRule, globals} = require './rule-test-helper'

# rule dep
component = require '../make/component'

_feature = (dst) -> "#{globals.featurePath}/#{dst}"
_build = (script) ->  "#{globals.lake.featureBuildDirectory}/#{globals.featurePath}/#{script}"

describe 'component rule', ->
    it 'should create component.json targets', (done) ->
        manifest =
            client:
                scripts: ['foo.coffee']
                main: 'foo.coffee'

        targets = executeRule component, {}, manifest
        expect(targets).to.have.property(_feature "build")
        expect(targets).to.have.property('build')

        done()

