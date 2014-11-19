# external dep
{expect} = require 'chai'
debug = require('debug')('rplan.tools.rules')

# local dep
{executeRule, globals} = require './rule-test-helper'

# rule dep
component1Build = require '../component1-build'

_feature = (dst) -> "#{globals.featurePath}/#{dst}"
_build = (script) ->  "#{globals.featureBuildDirectory}/#{globals.featurePath}/#{script}"


describe 'component1-build rule', ->
    it 'should create a component1-build target', (done) ->
        manifest =
            client: {}

        targets = executeRule component1Build, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        expect(targets).to.have.property(globals.remoteComponentPath)
        expect(targets).to.have.property(_feature('component1-build'))
        expect(targets).to.have.phonyTarget(_feature('component1-build'))

        done()

    it 'should create it\'s getTarget(\'component1-build\')', (done) ->
        manifest =
            client: {}

        targets = executeRule component1Build, {}, manifest
        componentBuildTarget = component1Build.getTargets(_build(''), 'component1-build')
        expect(targets).to.have.property(componentBuildTarget.target)

        done()
