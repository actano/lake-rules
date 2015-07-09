# Std Library
path = require 'path'

# Rule dep
component = require('./component')

# Local dep
{addJadeHtmlRule} = require './helper/jade'
Rule = require './helper/rule'
{config, getManifest} = require './lake/config'

exports.title = 'menu'
exports.readme =
    name: 'menu'
    path: path.join __dirname, 'menu.md'
exports.description = 'build html files for the webapp menu'

_makeArray = (value) -> [].concat(value or [])

# adds rules to create a single HTML file for a menu entry
createHtml = (manifest, buildPath, menuItem, domain, pagePath) ->
    # TODO should be relative to manifest, not config
    childManifest = getManifest menuItem.page

    if not childManifest?.page?.index?.jade?
        throw new Error("Feature #{menuItem.page} does not specfify a page view")

    html = path.join buildPath, path.resolve('.', pagePath), 'index.html'
    jade = path.join childManifest.featurePath, childManifest.page.index.jade
    obj = page:
        path: pagePath
        name: childManifest.name
        url: "/pages/#{childManifest.name}"
        i18nTag: menuItem.i18nTag
        domain: domain

    jadeDeps = _makeArray(childManifest?.page?.index?.dependencies).map (dep) ->
        path.normalize(path.join manifest.featurePath, dep)

    jadeBuildDeps = jadeDeps.map (dep) ->
        component.getComponentTarget path.join(config.featureBuildDirectory, dep)

    addJadeHtmlRule jade, html, obj, jadeBuildDeps, jadeDeps

_walkManifest = (manifest, cb) ->
    for name, filename of manifest.menus
        pageManifest = require path.resolve path.join manifest.featurePath, filename
        _walkMenuTree name, pageManifest.root, pageManifest.root.domain, '', cb

_walkMenuTree = (menuName, menuItem, domain, parentPath, cb) ->
    pagePath = parentPath + (menuItem.path ? '')
    if menuItem.page?
        cb(menuName, menuItem, domain, pagePath)
    if menuItem.children?
        # N.B. paths in the menu structure already have a '/', so use + instead of path.join
        childPath = parentPath + menuItem.path
        for child in menuItem.children
            _walkMenuTree menuName, child, domain, childPath, cb

module.exports.installMenu = (manifest, buildPath) ->
    targets = []
    _walkManifest manifest, (menuName, menuItem, domain, pagePath) ->
        targets.push createHtml manifest, buildPath, menuItem, pagePath
    return targets

exports.addRules = (manifest) ->
