# external dep
path = require 'path'
{expect} = require 'chai'
debug = require('debug')('rplan.tools.rules')

# local dep
{executeRule, globals} = require './rule-test-helper'

# rule dep
component = require '../make/component'

_feature = (dst) -> "#{globals.featurePath}/#{dst}"
_build = (script) ->  "#{globals.lake.featureBuildDirectory}/#{globals.featurePath}/#{script}"

_checkTargetsHaveTargetAndDependency = (targets, target, dependency) ->
    expect(targets).to.have.property(target)
    expect(targets[target].dependencies).to.match(new RegExp(dependency))


describe 'component rule', ->
    it 'should create component.json targets', (done) ->
        manifest =
            client:
                scripts: ['foo.coffee']
                main: 'foo.coffee'

        targets = executeRule component, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        expect(targets).to.have.property(_feature "build")
        expect(targets).to.have.property('build')

        expect(targets).to.have.property(_build 'component.json')
        expect(targets[_build 'component.json'].dependencies).to.match(/Manifest.coffee/)
        expect(targets[_build 'component.json'].dependencies).to.match(/foo.js/)

        done()

    it 'should create coffee script rules', (done) ->
        manifest =
            client:
                scripts: ['foo.coffee']
                main: 'foo.coffee'

        targets = executeRule component, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        _checkTargetsHaveTargetAndDependency(targets, _build('foo.js'), _feature('foo.coffee'))

        done()

    it 'should create jade template rules', (done) ->
        manifest =
            client:
                templates: ['foo.jade']

        targets = executeRule component, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        _checkTargetsHaveTargetAndDependency(targets, _build('foo.js'), _feature('foo.jade'))

        done()

    it 'should create stylus rules', (done) ->
        manifest =
            client:
                styles: ['foo.styl']

        targets = executeRule component, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        _checkTargetsHaveTargetAndDependency(targets, _build('foo.css'), _feature('foo.styl'))

        done()

    it 'should create image rules', (done) ->
        manifest =
            client:
                images: ['foo.png']

        targets = executeRule component, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        _checkTargetsHaveTargetAndDependency(targets, _build('foo.png'), _feature('foo.png'))

        done()

    it 'should add local dependencies to component.json', (done) ->
        manifest =
            client:
                scripts: ['foo.coffee']
                main: 'foo.coffee'
                dependencies:
                    production:
                        local: ['../otherFeature']

        targets = executeRule component, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        _checkTargetsHaveTargetAndDependency(
            targets, _build('component.json'), path.normalize(_build('../otherFeature')))

        done()

