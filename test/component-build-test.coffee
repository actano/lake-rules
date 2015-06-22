# external dep
{expect} = require 'chai'
debug = require('debug')('rplan.tools.rules')

# local dep
{executeRule, globals} = require './rule-test-helper'

# rule dep
componentBuild = require '../component-build'

describe 'component-build rule', ->
    it 'should create a component-build target', (done) ->
        manifest =
            client:
                dependencies: {}

        targets = executeRule componentBuild, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        expect(targets).to.have.property(globals.remoteComponentPath)
        expect(targets).to.have.property(manifest._feature('component-build'))
        expect(targets).to.have.phonyTarget(manifest._feature('component-build'))

        done()

    it 'should create it\'s getTarget(\'component-build\')', (done) ->
        manifest =
            client: {}

        targets = executeRule componentBuild, {}, manifest
        componentBuildTarget = componentBuild.getComponentBuildTargets manifest._build('')
        expect(targets).to.have.property(componentBuildTarget.target)

        done()
