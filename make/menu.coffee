path = require 'path'
{
    addMkdirRule
} = require '../rulebook_helper'

exports.description = ''
exports.addRules = (lake, featurePath, manifest, rb) ->
    return if not manifest.menus?

    buildPath = path.join lake.featureBuildDirectory, featurePath

    _addJadeTarget = (menuName, menuItem, pagePath) ->
        childManifest = require path.resolve(path.join(manifest.projectRoot, menuItem.page, 'Manifest'))

        if not childManifest?.page?.index?.jade?
          throw new Error("Feature #{menuItem.page} does not specfify a page view")

        html = path.join buildPath, 'menu', menuName, path.resolve('.', pagePath), 'index.html'
        jade = path.join featurePath, '..', name, childManifest.page.index.jade

        htmlDir = addMkdirRule rb, path.dirname html

        rb.addRule html, '[]', ->
            targets: html
            dependencies: [jade, '|', htmlDir]
            actions: "$(JADEC) $^ --pretty --out $(@D) --obj '{page: {path: \"#{pagePath}\", name: \"#{childManifest.name}\", url: \"/pages/#{childManifest.name}\"}}'"

        rb.addRule path.join(featurePath, 'build', html), [], ->
            targets: path.join featurePath, 'build'
            dependencies: html

    # walks through the menu structure and calls _addJadeTarget
    _createTargetForPage = (menuName, menuItem, parentPath) ->
        pagePath = parentPath + (menuItem.path ? '')
        if menuItem.page?
          _addJadeTarget(menuName, menuItem, pagePath)
        if menuItem.children?
            # TODO remove '/' from menu structure and use path.join instead of string concat
            childPath = parentPath + menuItem.path
            for child in menuItem.children
                _createTargetForPage menuName, child, childPath

    # create targets for each menu in the manifest
    for name, filename of manifest.menus
        pageManifest = require path.resolve(path.join(featurePath, filename))
        _createTargetForPage name, pageManifest.root, ''
