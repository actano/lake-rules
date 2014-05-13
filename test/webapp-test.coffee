proxyquire = require('proxyquire').noCallThru()

menuManifest =
    menus:
        name: 'model.coffee'
menuModel =
    root:
        path: ''
        children: [{
            path: '/a'
            i18nTag: 'page-a'
            page: 'lib/a'
        },{
            path: '/b'
            i18nTag: 'page-b'
            page: 'lib/b'
        }]

menu = proxyquire '../make/menu',
    '/project/root/lib/menu/Manifest': menuManifest
    '/project/root/lib/menu/model.coffee': menuModel
    '/Users/rh/Development/actano/rplan/tools/rules/test/lib/menu/model.coffee': menuModel

webappRule = proxyquire '../make/webapp',
    './menu': menu

{executeRule} = require './rule-test-helper'
{expect} = require 'chai'

describe 'webapp rule', ->

    beforeEach ->
        require('../helper/phony').clearPhonyCache()

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
        expect(install).to.depend 'lib/apiA/install'
        expect(install).to.depend 'lib/apiB/install'

    it 'installs all page dependecies', ->
        manifest =
            webapp:
                widgets: ['../pageA', '../pageB']
        targets = executeRule webappRule, {}, manifest
        install = targets['lib/feature/install']
        expect(install).to.depend 'lib/feature/widgets'
        widgets = targets['lib/feature/widgets']
        expect(widgets).to.depend 'lib/feature/widgets/lib/pageA'
        expect(widgets).to.depend 'lib/feature/widgets/lib/pageB'

    it 'copies a widget', ->
        manifest =
            webapp:
                widgets: ['../pageA']
        targets = executeRule webappRule, {}, manifest
        widget = targets['lib/feature/widgets/lib/pageA']
        expect(widget).to.depend 'build/local_components/lib/pageA/component-build/component-is-build'
        expect(widget).to.have.a.singleMakeAction /^rsync.*\s+build\/runtime\/lib\/feature\/widgets$/

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

    it 'copies the menu files', ->
        manifest =
            webapp:
                menu:
                    name: '../menu'

        targets = executeRule webappRule, {}, manifest
        #console.log targets
