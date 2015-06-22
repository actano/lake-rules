describe 'webapp rule', ->
    proxyquire = require 'proxyquire'
        .noCallThru()
    sinon = require 'sinon'
    {expect} = require 'chai'
        .use require 'sinon-chai'
    path = require 'path'

    _runtime = (file) -> path.join globals.runtimePath, file

    {executeRule, globals} = require './rule-test-helper'

    menuMock =
        installMenu: sinon.stub().returns []
    webappRule = proxyquire '../webapp',
        './menu': menuMock


    it 'extend the global install rule', ->
        manifest =
            webapp: {}
        targets = executeRule webappRule, {}, manifest
        expect(targets['install']).to.depend 'lib/feature/install'

    it 'installs all rest api dependecies', ->
        manifest =
            webapp:
                restApis: ['../apiA', '../apiB']
        targets = executeRule webappRule, {}, manifest
        install = targets['lib/feature/install']
        expect install
            .to.depend 'lib/feature/restApis'
        restApis = targets['lib/feature/restApis']
        expect(restApis).to.depend 'lib/apiA/install'
        expect(restApis).to.depend 'lib/apiB/install'

    it 'installs all page dependecies', ->
        manifest =
            webapp:
                widgets: ['../pageA', '../pageB']
        manifestA = client: {}
        manifestB = client: {}
        targets = executeRule webappRule, {}, manifest,
            '../pageA': manifestA
            '../pageB': manifestB
        install = targets['lib/feature/install']

        expect(install).to.depend 'lib/feature/widgets'
        widgets = targets['lib/feature/widgets']
        expect(widgets).to.depend _runtime 'lib/feature/widgets/pageA.js'
        expect(widgets).to.depend _runtime 'lib/feature/widgets/pageB.js'

    it 'sets install as phony', ->
        manifest =
            webapp: {}
        targets = executeRule webappRule, {}, manifest
        expect(targets).to.have.phonyTarget 'lib/feature/install'

    it 'sets install/widgets as phony', ->
        manifest =
            webapp:
                widgets: {}
        targets = executeRule webappRule, {}, manifest
        expect(targets).to.have.phonyTarget 'lib/feature/widgets'

    it 'installs menu files', ->
        manifest =
            webapp:
                menu:
                    name: '../menu'

        menuMock.installMenu.reset()
        depManifest = {}
        executeRule webappRule, {}, manifest, '../menu': depManifest
        expect menuMock.installMenu
            .to.be.calledWith sinon.match.any, depManifest, "#{globals.runtimePath}/lib/feature/menus/name"
