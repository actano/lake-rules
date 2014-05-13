# external dep
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

        expect(targets).to.have.property(_build 'foo.js')
        expect(targets[_build 'foo.js'].dependencies).to.match(/foo.coffee/)

        done()

    it 'should create jade template rules', (done) ->
        manifest =
            client:
                templates: ['foo.jade']

        targets = executeRule component, {}, manifest
        #debug JSON.stringify targets, null, '\t'

        expect(targets).to.have.property(_build 'foo.js')
        expect(targets[_build 'foo.js'].dependencies).to.match(/foo.jade/)

        done()
