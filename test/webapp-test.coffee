sinon = require 'sinon'

webappRule = require '../make/webapp'
menu = require '../make/menu'

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

        getTargets = sinon.stub(menu, "getTargets")
        getTargets.returns [
            ['build/local_components/lib/menu/menu/name', 'a/index.html']
            ['build/local_components/lib/menu/menu/name', 'b/index.html']
        ]

        try
            targets = executeRule webappRule, {}, manifest
            expect(targets['build/runtime/lib/feature/menus/name/a/index.html']).to.copy 'build/local_components/lib/menu/menu/name/a/index.html'
            expect(targets['build/runtime/lib/feature/menus/name/b/index.html']).to.copy 'build/local_components/lib/menu/menu/name/b/index.html'
        finally
            getTargets.restore()

    it 'installs menu files', ->
        manifest =
            webapp:
                menu:
                    name: '../menu'
        getTargets = sinon.stub(menu, "getTargets")
        getTargets.returns [
            ['build/local_components/lib/menu/menu/name', 'a/index.html']
            ['build/local_components/lib/menu/menu/name', 'b/index.html']
        ]

        try
            targets = executeRule webappRule, {}, manifest
            expect(targets['lib/feature/install']).to.depend 'lib/feature/menus'
            expect(targets).to.have.phonyTarget 'lib/feature/menus'
        finally
            getTargets.restore()
