# Std library
path = require 'path'

# Local dep
{resolveLocalComponentPaths} = require "./rulebook_helper"

exports.title = 'component'
exports.description = "build and install components"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join featurePath, lake.featureBuildDirectory # lib/foobar/build
    componentsPath = path.join buildPath, "components" # lib/foobar/build/components
    componentBuildDirectory = "component-build" # lib/foobar/build/component-build

    # project root relative paths
    projectRoot = path.resolve lake.lakePath, ".." # project root
    localComponentPath = path.join lake.localComponentsPath, featurePath # build/runtime/lib/foobar 

    # Manifest -> component_generator -> component.json
    if manifest.client?
        if manifest.client.main?
            rb.addRule "component.json", ["client"], ->
                targets: path.join buildPath, "component.json"
                dependencies: path.join featurePath, "Manifest.coffee"
                actions: [
                    "mkdir -p #{buildPath}"
                    "$(COMPONENT_GENERATOR) $< $@"
                ]

    # install remote dependencies
    if manifest.client?.dependencies?
        rb.addRule "component-install", ["client"], ->
            targets: componentsPath
            dependencies: [
                rb.getRuleById("component.json").targets
                resolveLocalComponentPaths manifest.client.dependencies.production.local, projectRoot, featurePath, lake.localComponentsPath
            ]
            actions: [
                "cd #{buildPath} && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf #{componentsPath}"
                "test -d #{componentsPath}"
                "touch #{componentsPath}"
            ]

    # build foobar.js and foobar.css (add require, concat files)
    if manifest.client?.dependencies?.production?.local?
        jsFile = path.join(buildPath, manifest.name) + ".js"
        cssFile = path.join(buildPath, manifest.name) + ".css"
        rb.addRule "component-build", ["client"], ->
            targets: [jsFile, cssFile]
            dependencies: [
                rb.getRuleById("component.json").targets
                rb.getRuleById("component-install").targets
                # NOTE: path for foreign components is relative, need to resolve it by build the absolute before
                resolveLocalComponentPaths manifest.client.dependencies.production.local, projectRoot, featurePath, lake.localComponentsPath
                rule.targets for rule in rb.getRulesByTag 'coffee-client'
                rb.getRuleById('stylus', {}).targets
                rule.targets for rule in rb.getRulesByTag 'jade-partials'
            ]
            # NOTE: component-build don't use (makefile) dependencies paramter, it parse the component.json
            actions: [
                "cd #{buildPath} && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) --name #{manifest.name} -v -o #{componentBuildDirectory}"
                "cp -fr #{path.join buildPath, componentBuildDirectory}/* #{buildPath}"
                "test -f #{jsFile} || touch #{jsFile}"
                "test -f #{cssFile} || touch #{cssFile}"
            ]

    # install local dependencies (local components)
    if manifest.client? and manifest.client?.dependencies?.production?.local?
        rb.addRule "local-components", ["feature"], ->
            targets: localComponentPath
            dependencies: rb.getRuleById("component-build", {}).targets
            actions: [
                "mkdir -p #{localComponentPath}"
                # link everything in the build directory (TOOD: refactor from implicit to explicit)
                "cp -fr #{buildPath}/* #{localComponentPath}"
                "touch #{localComponentPath}"
            ]
