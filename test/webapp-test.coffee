describe 'webapp rule', ->
    Rule = require '../helper/rule'

    proxyquire = require 'proxyquire'
        .noCallThru()
    sinon = require 'sinon'
    {expect} = require 'chai'
        .use require 'sinon-chai'
    path = require 'path'

    {config} = require '../lake/config'

    {executeRule} = require './rule-test-helper'

    webappRule = require '../webapp'

    before ->
        Rule.writable = write: ->

    after ->
        Rule.writable = null


    it 'extend the global install rule', ->
        manifest =
            webapp: {}
        targets = executeRule webappRule, manifest
        expect(targets['install']).to.depend 'lib/feature/install'

    it 'installs all rest api dependecies', ->
        manifest =
            webapp:
                restApis: ['../apiA', '../apiB']
        targets = executeRule webappRule, manifest
        install = targets['lib/feature/install']
        expect install
            .to.depend 'lib/feature/restApis'
        restApis = targets['lib/feature/restApis']
        expect(restApis).to.depend 'lib/apiA/install'
        expect(restApis).to.depend 'lib/apiB/install'

    it 'sets install as phony', ->
        manifest =
            webapp: {}
        targets = executeRule webappRule, manifest
        expect(targets).to.have.phonyTarget 'lib/feature/install'
