###

  TODO Building a menu has a lot of inter-feature dependencies which are not always clearly specified.

  We need to clean these up in order to make the build more transparent. Open issues are:
  - The URL where the main component will be mounted is known by this rule file and lib/webapp/webapp.coffee (namely
    under /pages/FEATURE-NAME.{js,css})
  - The model-config.coffee references other features to be rendered. This information is only used by this rule file.
    However, the information must be parsed from a coffee file and is not directly specified in the Manifest like other
    build information.
  - The generated file structure is known by lib/webapp/webapp.coffee. Probably not as bad, as this would be solved
    by serving the files using a static web server. (cf. pages in webapp)

###

# Std Library
path = require 'path'

# Local dep
{addMkdirRule} = require '../helper/filesystem'
{addJadeHtmlRule} = require '../helper/jade'

exports.title = 'menu'
exports.readme =
    name: 'menu'
    path: path.join __dirname, 'menu.md'
exports.description = 'build html files for the webapp menu'
exports.addRules = (lake, featurePath, manifest, rb) ->
    return if not manifest.menus?

    buildPath = path.join lake.featureBuildDirectory, featurePath

    # adds rules to create a single HTML file for a menu entry
    _addJadeTarget = (menuName, menuItem, pagePath) ->
        childManifest = require path.resolve(path.join(manifest.projectRoot, menuItem.page, 'Manifest'))

        if not childManifest?.page?.index?.jade?
          throw new Error("Feature #{menuItem.page} does not specfify a page view")

        html = path.join buildPath, 'menu', menuName, path.resolve('.', pagePath), 'index.html'
        jade = path.join featurePath, '..', menuName, childManifest.page.index.jade
        obj = page:
            path: pagePath
            name: childManifest.name
            url: "/pages/#{childManifest.name}"
            i18nTag: menuItem.i18nTag

        addJadeHtmlRule rb, jade, html, obj

        rb.addRule path.join(featurePath, 'build', html), [], ->
            targets: path.join featurePath, 'build'
            dependencies: html

    # create targets for each menu in the manifest
    _walkManifest manifest, _addJadeTarget

module.exports.getTargets = (manifest, tag) ->
    if not manifest.webapp?.menu? and not manifest.webapp?.menu[tag]?
        throw new Error("Unknown menu #{tag}")

    # tag is a bit misused: it's the name of the menu entry

    menuManifestPath = path.join(manifest.projectRoot, manifest.featurePath, manifest.webapp.menu[tag], 'Manifest')
    menuManifest = require menuManifestPath
    menuManifest.featurePath = path.relative manifest.projectRoot, path.dirname(menuManifestPath)

    buildPath = path.join 'build', 'local_components', menuManifest.featurePath

    targets = []
    _walkManifest menuManifest, (menuName, menuItem, pagePath) ->
        html = [path.join(buildPath, 'menu', menuName), path.join(path.resolve('.', pagePath), 'index.html')]
        targets.push html
    return targets

_walkManifest = (manifest, cb) ->
    for name, filename of manifest.menus
        pageManifest = require path.resolve(path.join(manifest.featurePath, filename))
        _walkMenuTree name, pageManifest.root, '', cb

_walkMenuTree = (menuName, menuItem, parentPath, cb) ->
    pagePath = parentPath + (menuItem.path ? '')
    if menuItem.page?
        cb(menuName, menuItem, pagePath)
    if menuItem.children?
        # N.B. paths in the menu structure already have a '/', so use + instead of path.join
        childPath = parentPath + menuItem.path
        for child in menuItem.children
            _walkMenuTree menuName, child, childPath, cb
