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
        expect(targets[_build 'component.json']).depend(_feature 'Manifest.coffee')
        expect(targets[_build 'component.json']).depend(_build 'foo.js')

        done()

    it 'should create coffee script rules', (done) ->
        manifest =
            client:
                scripts: ['foo.coffee']
                main: 'foo.coffee'

        targets = executeRule component, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        expect(targets[_build('foo.js')]).depend _feature('foo.coffee')

        done()

    it 'should create jade template rules', (done) ->
        manifest =
            client:
                templates: ['foo.jade']

        targets = executeRule component, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        expect(targets[_build('foo.js')]).depend _feature('foo.jade')

        done()

    it 'should create stylus rules', (done) ->
        manifest =
            client:
                styles: ['foo.styl']

        targets = executeRule component, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        expect(targets[_build('foo.css')]).depend _feature('foo.styl')

        done()

    it 'should create image rules', (done) ->
        manifest =
            client:
                images: ['foo.png']

        targets = executeRule component, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        expect(targets[_build('foo.png')]).depend _feature('foo.png')

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

        expect(targets[_build('component.json')]).depend  path.normalize(_build('../otherFeature/component.json'))

        done()

