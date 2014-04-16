###
#
    generates make rules for a node rest-api

    defines the following main make targets:

    feature/build:
        compiles all server scripts to javascript

        output contract:
            places javascript files in BUILD_DIR/FEATURE_DIR/server_scripts

    feature/run:
        starts node with the main server script inside the build directory

    feature/install:
        copies all servers scripts to the runtime directory

        output contract:
            places javascript files in RUNTIME_DIR/FEATURE_DIR

    feature/unit_test:
        runs mocha on the given test files

        output contract:
            writes a XML test report to REPORT_DIR/FEATURE_DIR

    feature/build, feature/install and feature/unit_test are appended to
    build, install and unit_test respectively.

###

# Std library
path = require 'path'

# Third party
# TODO remove when i18n is removed
glob = require 'glob'

# Local dep
{
    replaceExtension
    addCopyRule
    addMkdirRule
    addPhonyRule
} = require "../rulebook_helper"

exports.description = "build a rest-api feature"
exports.addRules = (lake, featurePath, manifest, rb) ->
    return if not manifest.server?

    if manifest.server.scripts?.dirs?
        throw new Error("Directory entries are not supported in the manifest (#{featurePath})")

    buildDependencies = []
    runtimeDependencies = []

    buildPath = path.join lake.featureBuildDirectory, featurePath
    runtimePath = path.join lake.runtimePath, featurePath

    _src = (script) -> path.join featurePath, script
    _dst = (script) -> path.join buildPath, 'server_scripts', replaceExtension(script, '.js')
    _run = (script) -> path.join runtimePath, replaceExtension(script, '.js')
    _local = (target) -> path.join featurePath, target

    # Until the switch to alien is complete, we need to copy i18n resources.
    # TODO Remove this once we don't need i18n!
    if manifest.resources?.dirs?
        for dir in manifest.resources.dirs
            resourcesPath = path.join featurePath, dir
            resourcesBuildPath = path.join buildPath, dir
            resourceFiles = glob.sync "*", cwd: path.resolve resourcesPath
            for resourceFile in resourceFiles
                src = path.join resourcesPath, resourceFile
                dst = path.join buildPath, dir, resourceFile
                run = path.join runtimePath, dir, resourceFile
                buildDependencies.push dst
                runtimeDependencies.push run
                do (src, dst, run) ->
                    addCopyRule rb, src, dst
                    addCopyRule rb, src, run

    # Build targets
    if manifest.server.scripts?.files?
        for script in manifest.server.scripts.files
            src = _src script
            dst = _dst script
            do (src, dst) ->
                buildDependencies.push dst

                dstPath = addMkdirRule rb, path.dirname dst
                rb.addRule dst, [], ->
                    targets: dst
                    dependencies: [src, '|', dstPath]
                    actions: "$(COFFEEC) $(COFFEE_FLAGS) --output #{dstPath} $^"

    rb.addRule 'build', [], ->
        targets: _local 'build'
        dependencies: buildDependencies
    addPhonyRule rb, _local 'build'

    rb.addRule 'build (global)', [], ->
        targets: 'build'
        dependencies: _local 'build'

    rb.addRule 'run', [], ->
        targets: _local 'run'
        dependencies: _local 'build'
        actions: "$(NODE) #{path.join buildPath, 'server_scripts', 'server'}"
    addPhonyRule rb, _local 'run'

    # Install / Dist targets
    if manifest.server.scripts?.files?
        for script in manifest.server.scripts.files
            src = _dst script
            dst = _run script
            do (src, dst) ->
                runtimeDependencies.push dst
                addCopyRule rb, src, dst

    rb.addRule 'install', [], ->
        targets: _local 'install'
        dependencies: runtimeDependencies
    addPhonyRule rb, _local 'install'

    rb.addRule 'install (global)', [], ->
        targets: 'install'
        dependencies: _local 'install'

    # Test targets
    if manifest.server?.tests?
        _getParams = (file) ->
            params = ''
            if manifest.server.testParams?
                for testParam in manifest.server.testParams
                    if file.indexOf(testParam.file) > -1
                        params += " #{testParam.param}"
            return params

        _getTestAction = (testFile) ->
            fullPath = path.join featurePath, testFile
            params = _getParams fullPath
            report = path.join(featurePath, path.basename(fullPath, path.extname(fullPath))) + '.xml'
            "PREFIX=#{lake.testReportPath} REPORT_FILE=#{report} $(MOCHA)#{params} -R $(MOCHA_REPORTER) $(MOCHA_COMPILER) #{fullPath}"

        reportPath = path.join lake.testReportPath, featurePath
        addMkdirRule rb, reportPath

        rb.addRule 'unit-test', [], ->
            targets: _local 'unit_test'
            dependencies: [path.join(featurePath, 'build'), '|', reportPath]
            actions: _getTestAction testFile for testFile in manifest.server.tests
        addPhonyRule rb, _local 'unit_test'

        rb.addRule 'unit-test (global)', [], ->
            targets: 'unit_test'
            dependencies: _local 'unit_test'
