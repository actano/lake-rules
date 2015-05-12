{coffeeAction} = require '../helper/coffeescript'
databaseRule = require '../database'
{expect, Assertion} = require 'chai'
{executeRule, globals} = require './rule-test-helper'
path = require 'path'

_build = (file) -> path.join globals.featureBuildDirectory, globals.featurePath, file
_local = (file) -> path.join globals.featurePath, file

describe 'database rule', ->
    it 'should build view scripts', ->
        manifest =
            database:
                designDocuments: ['database/view1.js', 'database/view2.coffee']

        targets = executeRule databaseRule, {}, manifest

        expect(targets[_build 'database/view1.js']).to.copy _local 'database/view1.js'
        expect(targets[_build 'database/view2.js']).to.containAction coffeeAction

    it 'should create couchview targets', ->
        manifest =
            database:
                designDocuments: ['database/view1.js', 'database/view2.coffee']

        targets = executeRule databaseRule, {}, manifest

        expect(targets).to.have.phonyTarget _local 'database/view1.js/couchview'
        expect(targets).to.have.phonyTarget _local 'database/view2.coffee/couchview'
        expect(targets[_local 'database/view1.js/couchview']).to.depend _build 'database/view1.js'
        expect(targets[_local 'database/view2.coffee/couchview']).to.depend _build 'database/view2.js'

        expect(targets[_local 'couchview']).to.depend [_local('database/view1.js/couchview'), _local('database/view2.coffee/couchview')]
        expect(targets).to.have.phonyTarget _local 'couchview'

        expect(targets['couchview']).to.depend _local 'couchview'

