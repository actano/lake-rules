
restApiRule = require '../make/rest-api'
{executeRule, checkTargets} = require './rule-test-helper'
{expect} = require 'chai'

describe 'rest-api rule', ->
    it 'should include build dependencies', (done) ->
        manifest =
            server:
                dependencies:
                    production:
                        local: ['../depA', '../depB']

        targets = executeRule restApiRule, {}, manifest
        build = targets['lib/feature/build']
        expect(build).to.depend 'lib/depA/build'
        expect(build).to.depend 'lib/depB/build'

        done()

    it 'should include test dependencies', (done) ->
        manifest =
            server:
                dependencies:
                    production:
                        local: ['../depA', '../depB']

        targets = executeRule restApiRule, {}, manifest
        preUnitTest = targets['lib/feature/pre_unit_test']
        expect(preUnitTest).to.depend 'lib/depA/pre_unit_test'
        expect(preUnitTest).to.depend 'lib/depB/pre_unit_test'

        done()

    it 'should build server.coffee', (done) ->
        manifest =
            server:
                scripts:
                    files: ['server.coffee']

        targets = executeRule restApiRule, {}, manifest
        build = targets['lib/feature/build']
        expect(build).to.depend '/project/root/build/server/lib/feature/server.js'
        serverJs = targets['/project/root/build/server/lib/feature/server.js']
        expect(serverJs).to.exist

        done()

    it 'should alias the build target', (done) ->
        manifest = server: {}

        targets = executeRule restApiRule, {}, manifest
        expect(targets['lib/feature']).to.depend 'lib/feature/build'

        done()

    it 'should extend the global build target', (done) ->
        manifest = server: {}

        targets = executeRule restApiRule, {}, manifest
        expect(targets['build']).to.depend 'lib/feature/build'

        done()

    it 'should include install dependencies', (done) ->
        manifest =
            server:
                dependencies:
                    production:
                        local: ['../depA', '../depB']

        targets = executeRule restApiRule, {}, manifest
        install = targets['lib/feature/install']
        expect(install).to.depend 'lib/depA/install'
        expect(install).to.depend 'lib/depB/install'

        done()

    it 'should have install targets', (done) ->
        manifest =
            server:
                scripts:
                    files: ['server.coffee']

        targets = executeRule restApiRule, {}, manifest
        install = targets['lib/feature/install']
        expect(install).to.depend 'build/runtime/lib/feature/server.js'
        serverJs = targets['build/runtime/lib/feature/server.js']
        expect(serverJs).to.exist
        expect(serverJs).to.depend '/project/root/build/server/lib/feature/server.js'
        buildJs = targets['/project/root/build/server/lib/feature/server.js']
        expect(buildJs).to.exist
        expect(buildJs).to.depend 'lib/feature/server.coffee'
        expect(buildJs.actions).to.equal '$(NODE_BIN)/coffee --compile --map --output $(@D) $<'

        done()
