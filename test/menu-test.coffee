proxyquire = require('proxyquire').noCallThru()
{expect} = require 'chai'
{executeRule, globals} = require './rule-test-helper'
path = require 'path'
_ = require 'underscore'

featurePath = 'lib/testmenu'

_local = (file) -> path.join featurePath, file
_build = (file) -> path.join globals.lake.featureBuildDirectory, featurePath, file
_absolute = (file) -> path.join globals.manifest.projectRoot, file

manifest =
    featurePath: featurePath
    menus:
        testmenu: './menu-config.coffee'

menuConfig =
    root:
        path: ''
        children: [{
            path: '/feature1'
            i18nTag: 'page-feature1'
            page: 'lib/feature1'
        },
            {
                path: '/foo'
                i18nTag: 'lbl_foo'
                children: [{
                    path: '/feature2'
                    i18nTag: 'page-feature2'
                    page: 'lib/feature2'
                },
                    {
                        path: '/feature3'
                        i18nTag: 'page-feature3'
                        page: 'lib/feature3'
                    }]
            }]

menuConfigPath = path.resolve path.join featurePath, manifest.menus.testmenu
feature1Path = path.join globals.manifest.projectRoot, 'lib/feature1/Manifest'
feature2Path = path.join globals.manifest.projectRoot, 'lib/feature2/Manifest'
feature3Path = path.join globals.manifest.projectRoot, 'lib/feature3/Manifest'

menuMock = {}
menuMock[menuConfigPath] = menuConfig
menuMock[feature1Path] =
    name: 'feature1'
    page:
        index:
            jade: 'index.jade'
menuMock[feature2Path] =
    name: 'feature2'
    page:
        index:
            jade: 'index.jade'
menuMock[feature3Path] =
    name: 'feature3'
    page:
        index:
            jade: 'index.jade'

testmenuPath = path.join globals.manifest.projectRoot, featurePath, '../testmenu/Manifest'
menuMock[testmenuPath] = manifest

menuRule = proxyquire '../make/menu', menuMock

describe 'menu rules', ->
    it 'should create html files for the menu', ->
        targets = executeRule menuRule, {}, manifest

        expect(targets[_build 'menu/testmenu/feature1/index.html']).to.depend _absolute 'lib/feature1/index.jade'
        expect(targets[_build 'menu/testmenu/foo/feature2/index.html']).to.depend _absolute 'lib/feature2/index.jade'
        expect(targets[_build 'menu/testmenu/foo/feature3/index.html']).to.depend _absolute 'lib/feature3/index.jade'
        expect(targets[_local 'build']).to.depend [
            _build 'menu/testmenu/feature1/index.html'
            _build 'menu/testmenu/foo/feature2/index.html'
            _build 'menu/testmenu/foo/feature3/index.html'
        ]

    it 'should return the correct targets', ->
        manifest = _.chain(globals.manifest).clone().extend(
            featurePath: featurePath
            webapp:
                menu:
                    testmenu: '../testmenu'
        ).value()

        targets = menuRule.getTargets manifest, 'testmenu'
        targets = _(targets).map (x) -> x.join ''

        expect(targets).to.contain '$(LOCAL_COMPONENTS)/lib/testmenu/menu/testmenu/feature1/index.html'
        expect(targets).to.contain '$(LOCAL_COMPONENTS)/lib/testmenu/menu/testmenu/foo/feature2/index.html'
        expect(targets).to.contain '$(LOCAL_COMPONENTS)/lib/testmenu/menu/testmenu/foo/feature3/index.html'
