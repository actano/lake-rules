restApiRule = require '../rest-api'
{executeRule, globals} = require './rule-test-helper'
{expect} = require 'chai'
path = require 'path'

_runtime = (file) -> path.join globals.runtimePath, file
_absolute = (file) -> path.join globals.projectRoot, file

describe 'rest-api rule', ->
    it 'should include build dependencies', ->
        manifest =
            server:
                dependencies:
                    production:
                        local: ['../depA', '../depB']

        targets = executeRule restApiRule, {}, manifest
        build = targets['lib/feature/build']
        expect(build).to.depend 'lib/depA/build'
        expect(build).to.depend 'lib/depB/build'

    it 'should include test dependencies', ->
        manifest =
            server:
                dependencies:
                    production:
                        local: ['../depA', '../depB']

        targets = executeRule restApiRule, {}, manifest
        preUnitTest = targets['lib/feature/pre_unit_test']
        expect(preUnitTest).to.depend 'lib/depA/pre_unit_test'
        expect(preUnitTest).to.depend 'lib/depB/pre_unit_test'

    it 'should build server.coffee', ->
        manifest =
            server:
                scripts:
                    files: ['server.coffee']

        targets = executeRule restApiRule, {}, manifest
        build = targets['lib/feature/build']
        expect(build).to.depend '$(SERVER)/lib/feature/server.js'
        serverJs = targets['$(SERVER)/lib/feature/server.js']
        expect(serverJs).to.exist

    it 'should alias the build target', ->
        manifest = server: {}

        targets = executeRule restApiRule, {}, manifest
        expect(targets['lib/feature']).to.depend 'lib/feature/build'

    it 'should extend the global build target', ->
        manifest = server: {}

        targets = executeRule restApiRule, {}, manifest
        expect(targets['build']).to.depend 'lib/feature/build'

    it 'should include install dependencies', ->
        manifest =
            server:
                dependencies:
                    production:
                        local: ['../depA', '../depB']

        targets = executeRule restApiRule, {}, manifest
        install = targets['lib/feature/install']
        expect(install).to.depend 'lib/depA/install'
        expect(install).to.depend 'lib/depB/install'

    it 'should have install targets', ->
        manifest =
            server:
                scripts:
                    files: ['server.coffee', 'lib.coffee']

        targets = executeRule restApiRule, {}, manifest

        install = targets['lib/feature/install']
        expect(install).to.depend _runtime 'lib/feature/server.js'
        expect(install).to.depend _runtime 'lib/feature/lib.js'

        runtimeServerJs = targets[_runtime 'lib/feature/server.js']
        expect(runtimeServerJs).to.exist
        expect(runtimeServerJs).to.depend '$(SERVER)/lib/feature/server.js'

        runtimeLibJs = targets[_runtime 'lib/feature/lib.js']
        expect(runtimeLibJs).to.exist
        expect(runtimeLibJs).to.depend '$(SERVER)/lib/feature/lib.js'

        buildServerJs = targets['$(SERVER)/lib/feature/server.js']
        expect(buildServerJs).to.exist
        expect(buildServerJs).to.depend 'lib/feature/server.coffee'
        expect(buildServerJs).to.have.a.singleMakeAction '$(NODE_BIN)/coffee --compile --output $(@D) $<'

        buildLibJs = targets['$(SERVER)/lib/feature/lib.js']
        expect(buildLibJs).to.exist
        expect(buildLibJs).to.depend 'lib/feature/lib.coffee'
        expect(buildLibJs).to.have.a.singleMakeAction '$(NODE_BIN)/coffee --compile --output $(@D) $<'

    it 'should declare build as phony', ->
        manifest = server: {}

        targets = executeRule restApiRule, {}, manifest
        expect(targets).to.have.phonyTarget 'lib/feature/build'

    it 'should declare install as phony', ->
        manifest = server: {}

        targets = executeRule restApiRule, {}, manifest
        expect(targets).to.have.phonyTarget 'lib/feature/install'

    it 'should declare test as phony', ->
        manifest = server: {}

        targets = executeRule restApiRule, {}, manifest
        expect(targets).to.have.phonyTarget 'lib/feature/unit_test'

    it 'should run unit tests', ->
        manifest =
            server:
                test:
                    unit: ['test/unitA.coffee', 'test/unitB.coffee']
        targets = executeRule restApiRule, {}, manifest
        unitTest = targets['lib/feature/unit_test']
        expect(unitTest.actions).to.have.length 2
        expect(unitTest.actions[0]).to.match /\$\(MOCHA_RUNNER\) -R sternchen.*test\/unitA\.coffee/
        expect(unitTest.actions[1]).to.match /\$\(MOCHA_RUNNER\) -R sternchen.*test\/unitB\.coffee/

    it 'should copy test assets and exports', ->
        manifest =
            server:
                test:
                    assets: ['test/data/a.txt', 'test/data/b.txt']
                    exports: ['test/helper.coffee', 'test/lib.coffee']
        targets = executeRule restApiRule, {}, manifest
        preUnitTest = targets['lib/feature/pre_unit_test']
        expect(preUnitTest).to.depend '$(SERVER)/lib/feature/test/data/a.txt'
        expect(preUnitTest).to.depend '$(SERVER)/lib/feature/test/data/b.txt'
        expect(preUnitTest).to.depend '$(SERVER)/lib/feature/test/helper.coffee'
        expect(preUnitTest).to.depend '$(SERVER)/lib/feature/test/lib.coffee'

        expect(targets['$(SERVER)/lib/feature/test/data/a.txt']).to.copy 'lib/feature/test/data/a.txt'
        expect(targets['$(SERVER)/lib/feature/test/data/b.txt']).to.copy 'lib/feature/test/data/b.txt'
        expect(targets['$(SERVER)/lib/feature/test/helper.coffee']).to.copy 'lib/feature/test/helper.coffee'
        expect(targets['$(SERVER)/lib/feature/test/lib.coffee']).to.copy 'lib/feature/test/lib.coffee'

    it 'should add unit tests to the local test target', ->
        manifest =
            server:
                test:
                    unit: ['test/unit.coffee']

        targets = executeRule restApiRule, {}, manifest
        expect(targets['lib/feature/test']).to.depend 'lib/feature/unit_test'
