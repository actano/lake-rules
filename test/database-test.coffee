databaseRule = require '../database'
{expect} = require 'chai'
{executeRule} = require './rule-test-helper'
path = require 'path'


describe 'database rule', ->
    manifest = null

    beforeEach ->
        manifest =
            name: 'feature'
            database:
                designDocuments: ['database/view1.js', 'database/view2.coffee']

    it 'should build view scripts', ->
        targets = executeRule databaseRule, manifest

        expect(targets[manifest._build 'database/view1.js']).to.copy manifest._local 'database/view1.js'
        expect(targets[manifest._build 'database/view2.js']).to.useBuildServer 'coffee'

    it 'should create couchview targets', ->
        targets = executeRule databaseRule, manifest

        expect(targets).to.have.phonyTarget manifest._local 'database/view1.js/couchview'
        expect(targets).to.have.phonyTarget manifest._local 'database/view2.coffee/couchview'
        expect(targets[manifest._local 'database/view1.js/couchview']).to.depend manifest._build 'database/view1.js'
        expect(targets[manifest._local 'database/view2.coffee/couchview']).to.depend manifest._build 'database/view2.js'

        expect(targets[manifest._local 'couchview']).to.depend [manifest._local('database/view1.js/couchview'), manifest._local('database/view2.coffee/couchview')]
        expect(targets).to.have.phonyTarget manifest._local 'couchview'

        expect(targets['couchview']).to.depend manifest._local 'couchview'

