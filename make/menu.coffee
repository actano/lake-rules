###

  Generates make rules to build a "menu".

  TODO Building a menu has a lot of inter-feature dependencies which are not always clearly specified.

  We need to clean these up in order to make the build more transparent. Open issues are:
  - The URL where the main component will be mounted is known by this rule file and lib/webapp/webapp.coffee (namely
    under /pages/FEATURE-NAME.{js,css})
  - The model-config.coffee references other features to be rendered. This information is only used by this rule file.
    However, the information must be parsed from a coffee file and is not directly specified in the Manifest like other
    build information.
  - The generated file structure is known by lib/webapp/webapp.coffee. Probably not as bad, as this would be solved
    by serving the files using a static web server. (cf. pages in webapp)

  It defines the following targets:

  feature/build:

    builds a tree of HTML files at BUILD_DIR/FEATURE_DIR/menu/MENU_NAME/../index.html

###

path = require 'path'
{addMkdirRule} = require '../helper/filesystem'

exports.description = ''
exports.addRules = (lake, featurePath, manifest, rb) ->
    return if not manifest.menus?

    buildPath = path.join lake.featureBuildDirectory, featurePath

    # adds rules to create a single HTML file for a menu entry
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
            actions: "$(JADEC) --pretty --out \"$@\" \"$<\" --obj '{page: {path: \"#{pagePath}\", name: \"#{childManifest.name}\", url: \"/pages/#{childManifest.name}\", i18nTag: \"#{menuItem.i18nTag}\"}}'"

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
