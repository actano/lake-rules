# Std library
path = require 'path'
{_} = require 'underscore'

# Local dep
{resolveLocalComponentPaths, concatPaths, createPathInfo} = require "./rulebook_helper"

exports.title = 'component'
exports.description = "build and install components"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join featurePath, lake.featureBuildDirectory # lib/foobar/build
    componentInstallDirectory = "components"
    componentInstalledTouchFile = path.join buildPath, "#{componentInstallDirectory}-installed"
    componentsPath = path.join buildPath, componentInstallDirectory # lib/foobar/build/components
    componentBuildDirectory = "component-build" # lib/foobar/build/component-build


    # project root relative paths
    projectRoot = path.resolve lake.lakePath, ".." # project root
    remoteComponentPath = path.join projectRoot, lake.remoteComponentPath

    # Manifest -> component_generator -> component.json
    if manifest.client?.scripts?.length or manifest.client?.styles?.length
        rb.addRule "component.json", ["client", 'component-build-prerequisite'], ->
            targets: path.join buildPath, "component.json"
            dependencies: path.join featurePath, "Manifest.coffee"
            actions: [
                "mkdir -p #{buildPath}"
                "$(COMPONENT_GENERATOR) $< $@"
            ]

    # install remote dependencies

    if manifest.client?.dependencies?
        rb.addRule "component-install", ["client", 'component-build-prerequisite'], ->
            targets: componentInstalledTouchFile
            dependencies: [
                rb.getRuleById("component.json")?.targets
                resolveLocalComponentPaths manifest.client.dependencies.production.local, projectRoot, featurePath, lake.localComponentsPath
            ]
            actions: [
                # "cd #{buildPath} && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf #{componentsPath}"
                "test -d #{componentsPath} || ln -s #{remoteComponentPath} #{componentsPath}"
                "cd #{buildPath} && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm components*"
                "test -d #{componentsPath}"
                "touch -h #{componentsPath}"
                "touch #{componentInstalledTouchFile}"
            ]

    getComponentBuildDependencies = (rb) ->
        return _(rule.targets for rule in rb.getRulesByTag 'component-build-prerequisite').flatten()
    
    # copy images
    if manifest.client?.images?
        imageArray = manifest.client.images
        pathInfo = createPathInfo imageArray, featurePath, buildPath
        rb.addRule 'component-images', ['component-build-prerequisite'], ->
            targets: concatPaths imageArray, {pre: buildPath}
            dependencies: concatPaths imageArray, {pre: featurePath}
            actions: ("mkdir -p #{i.build.dirname} && cp #{i.src.path} #{i.build.path}" for i in pathInfo)

    # build foobar.js and foobar.css (add require, concat files)
    componentRule = manifest.client?.scripts?.length > 0 or
            manifest.client?.styles?.length > 0 or
            manifest.client?.fonts?.length > 0 or
            manifest.client?.images?.length > 0 or
            manifest.client?.fontsource?.length > 0


    if componentRule
        jsFile = path.join(buildPath, manifest.name) + ".js"
        cssFile = path.join(buildPath, manifest.name) + ".css"
        rb.addRule "component-build", ["client", "feature"], ->
            targets: [jsFile, cssFile]
            dependencies: [
                getComponentBuildDependencies rb
                resolveLocalComponentPaths manifest.client.dependencies?.production?.local, projectRoot, featurePath, lake.localComponentsPath
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
                "cp -fpr #{path.join buildPath, componentBuildDirectory}/* #{buildPath}"
                "touch #{jsFile}" # touch if no js file was generated
                "touch #{cssFile}" # touch if no css file was generated
            ]


        # install to local_components, so other componants can use us as dependency
        localComponentPath = path.join lake.localComponentsPath, featurePath

        rb.addRule "local-component", ["feature"], ->
            dependencies = getComponentBuildDependencies rb

            rule = {
                targets: localComponentPath
                dependencies: dependencies.concat rb.getRuleById('component-build', {}).targets
                actions: []
            }

            # NOTE: we can just use the component-build directory and copy everthing
            # instead of explicit listing
            # explicit listing doesn't work for dynmic stuff like fontcustom

            for file in dependencies
                destination = path.join localComponentPath, path.relative buildPath, file
                destinationDir = path.dirname destination

                rule.actions.push [
                    "mkdir -p #{destinationDir}"
                    "cp -fpr #{file} #{destinationDir}"
                ]

            rule.actions.unshift [
                "mkdir -p #{localComponentPath}"
                "cp -rpf #{path.join buildPath, componentBuildDirectory}/* #{localComponentPath}"
                "touch #{localComponentPath}"
            ]


            return rule
