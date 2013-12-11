# Std library
path = require 'path'
{_} = require 'underscore'

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

    # Manifest -> component_generator -> component.json
    if manifest.client?.scripts?.length or manifest.client?.styles?.length
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
                rb.getRuleById("component.json")?.targets
                resolveLocalComponentPaths manifest.client.dependencies.production.local, projectRoot, featurePath, lake.localComponentsPath
            ]
            actions: [
                "cd #{buildPath} && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf #{componentsPath}"
                "test -d #{componentsPath}"
                "touch #{componentsPath}"
            ]


    getComponentBuildDependencies = (rb) ->
        _.compact _.flatten [
            rb.getRuleById("component.json").targets
            rule.targets for rule in rb.getRulesByTag 'coffee-client'
            rb.getRuleById('stylus', {}).targets
            rb.getRuleById("component-install").targets
            rule.targets for rule in rb.getRulesByTag 'jade-partials'
        ]


    # build foobar.js and foobar.css (add require, concat files)
    if manifest.client?.scripts?.length > 0 or manifest.client?.styles?.length > 0
        jsFile = path.join(buildPath, manifest.name) + ".js"
        cssFile = path.join(buildPath, manifest.name) + ".css"
        rb.addRule "component-build", ["client", "feature"], ->
            targets: [jsFile, cssFile]
            dependencies: [
                getComponentBuildDependencies(rb)
                resolveLocalComponentPaths manifest.client.dependencies.production.local, projectRoot, featurePath, lake.localComponentsPath
            ]
            # NOTE: component-build doesn't use (makefile) dependencies parameter, it parses the component.json
            
            ###
            # TODO: rm -rf build/local_compents/lib/dependency
            # should not trigger a component build of a feature which has this 
            # dependency
            # 
            # Problem: component-build sometimes does not genrate a css file
            ###
            actions: [
                "cd #{buildPath} && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) --name #{manifest.name} -v -o #{componentBuildDirectory}"
                "cp -fr #{path.join buildPath, componentBuildDirectory}/* #{buildPath}"
                "touch #{jsFile}" # touch if no js file was generated
                "touch #{cssFile}" # touch if no css file was generated
            ]

    
    # install to local_components, so other componants can use us as dependency
    if manifest.client?.scripts?.length > 0 or manifest.client?.styles?.length > 0
        localComponentPath = path.join lake.localComponentsPath, featurePath

        rb.addRule "local-component", ["feature"], ->
            dependencies = getComponentBuildDependencies rb

            rule = {
                targets: localComponentPath
                dependencies: dependencies
                actions: []
            }

            for file in dependencies
                destination = path.join localComponentPath, path.relative buildPath, file
                destinationDir = path.dirname destination

                rule.actions.push [
                    "mkdir -p #{destinationDir}"
                    "cp -fr #{file} #{destinationDir}" 
                ]

            rule.actions.push "touch #{localComponentPath}"


            return rule
