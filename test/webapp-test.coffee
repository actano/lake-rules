webappRule = require '../webapp'
menu = require '../menu'

{executeRule, globals} = require './rule-test-helper'
{expect} = require 'chai'
sinon = require 'sinon'
path = require 'path'

_runtime = (file) -> path.join globals.runtimePath, file
_localComponents = (file) -> path.join globals.featureBuildDirectory, file

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
        expect(widget).to.depend _localComponents 'lib/pageA/component-build/component-is-build'
        expect(widget).to.have.a.singleMakeAction new RegExp("^rsync.+lib/pageA/component-build.+#{_runtime 'lib/feature/widgets'}$")

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
            [_localComponents('lib/menu/menu/name'), 'a/index.html']
            [_localComponents('lib/menu/menu/name'), 'b/index.html']
        ]

        try
            targets = executeRule webappRule, {}, manifest
            expect(targets[_runtime 'lib/feature/menus/name/a/index.html']).to.copy _localComponents 'lib/menu/menu/name/a/index.html'
            expect(targets[_runtime 'lib/feature/menus/name/b/index.html']).to.copy _localComponents 'lib/menu/menu/name/b/index.html'
        finally
            getTargets.restore()

    it 'installs menu files', ->
        manifest =
            webapp:
                menu:
                    name: '../menu'
        getTargets = sinon.stub(menu, "getTargets")
        getTargets.returns [
            [_localComponents('lib/menu/menu/name'), 'a/index.html']
            [_localComponents('lib/menu/menu/name'), 'b/index.html']
        ]

        try
            targets = executeRule webappRule, {}, manifest
            expect(targets['lib/feature/install']).to.depend 'lib/feature/menus'
            expect(targets).to.have.phonyTarget 'lib/feature/menus'
        finally
            getTargets.restore()

    describe 'website subsection', ->
        manifest = null

        beforeEach ->
            manifest =
                webapp:
                    website: 'foo'

        it 'installs the website', ->
            targets = executeRule webappRule, {}, manifest

            expect(targets['lib/feature/install']).to.depend 'build/runtime/lib/feature/website'
            expect(targets).to.have.phonyTarget 'build/runtime/lib/feature/website'

        it 'should use a .d file to prevent multiple installs', ->
            targets = executeRule webappRule, {}, manifest

            # we don't want to install the website every time to lower developer
            # build times
            expect(targets['build/runtime/lib/feature/website'])
                .to.depend 'build/runtime/lib/feature/website/node_modules.d'

        it 'should use $(NPM_INSTALL) to install the website', ->
            targets = executeRule webappRule, {}, manifest

            expect(targets['build/runtime/lib/feature/website/node_modules.d'])
                .to.containAction /\$\(NPM_INSTALL\) foo/
