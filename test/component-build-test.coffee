# external dep
{expect} = require 'chai'
debug = require('debug')('rplan.tools.rules')

# local dep
{executeRule, globals} = require './rule-test-helper'

# rule dep
componentBuild = require '../make/component-build'

_feature = (dst) -> "#{globals.featurePath}/#{dst}"
_build = (script) ->  "#{globals.lake.featureBuildDirectory}/#{globals.featurePath}/#{script}"


describe 'component-build rule', ->
    it 'should create a component-build target', (done) ->
        manifest =
            client: true

        targets = executeRule componentBuild, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        expect(targets).to.have.property(globals.lake.remoteComponentPath)
        expect(targets).to.have.property(_feature('component-build'))
        expect(targets).to.have.phonyTarget(_feature('component-build'))

        done()

    it 'should create his getTarget(\'component-build\')', (done) ->
        manifest =
            client: true

        targets = executeRule componentBuild, {}, manifest
        componentBuildTarget = componentBuild.getTargets(_build(''), 'component-build')
        expect(targets).to.have.property(componentBuildTarget.target)

        done()