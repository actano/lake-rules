proxyquire = require('proxyquire').noCallThru()
{expect} = require 'chai'
{executeRule} = require './rule-test-helper'
{config} = require '../lake/config'
path = require 'path'

featurePath = 'lib/testmenu'

_absolute = (file) -> path.join config.root, file

manifest =
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

menuConfigPath = path.resolve path.join (_absolute featurePath), manifest.menus.testmenu
feature1Path = _absolute 'lib/feature1/Manifest'
feature2Path = _absolute 'lib/feature2/Manifest'
feature3Path = _absolute 'lib/feature3/Manifest'

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

testmenuPath = path.join (_absolute featurePath), '../testmenu/Manifest'
menuMock[testmenuPath] = manifest

menuRule = proxyquire '../menu', menuMock

describe.skip 'menu rule', ->
    it 'should create html files for the menu', ->
        targets = executeRule menuRule, manifest

        expect(targets[manifest._build 'menu/testmenu/feature1/index.html']).to.depend _absolute 'lib/feature1/index.jade'
        expect(targets[manifest._build 'menu/testmenu/foo/feature2/index.html']).to.depend _absolute 'lib/feature2/index.jade'
        expect(targets[manifest._build 'menu/testmenu/foo/feature3/index.html']).to.depend _absolute 'lib/feature3/index.jade'
        expect(targets[manifest._local 'build']).to.depend [
            manifest._build 'menu/testmenu/feature1/index.html'
            manifest._build 'menu/testmenu/foo/feature2/index.html'
            manifest._build 'menu/testmenu/foo/feature3/index.html'
        ]

    it 'should return the correct targets', ->
        manifest =
            webapp:
                menu:
                    testmenu: '../testmenu'
        targets = menuRule.getTargets manifest, 'testmenu'
        targets = targets.map (x) -> x.join ''

        expect(targets).to.contain '$(LOCAL_COMPONENTS)/lib/testmenu/menu/testmenu/feature1/index.html'
        expect(targets).to.contain '$(LOCAL_COMPONENTS)/lib/testmenu/menu/testmenu/foo/feature2/index.html'
        expect(targets).to.contain '$(LOCAL_COMPONENTS)/lib/testmenu/menu/testmenu/foo/feature3/index.html'
