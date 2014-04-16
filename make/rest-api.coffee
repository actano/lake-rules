# Std library
path = require 'path'

# Third party
glob = require 'glob'

# Local dep
{
    replaceExtension
    addCopyRule
    addMkdirRule
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

    rb.addRule 'build (global)', [], ->
        targets: 'build'
        dependencies: _local 'build'

    rb.addRule 'run', [], ->
        targets: _local 'run'
        dependencies: _local 'build'
        actions: "$(NODE) #{path.join buildPath, 'server_scripts', 'server'}"

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

        rb.addRule 'unit-test (global)', [], ->
            targets: 'unit_test'
            dependencies: _local 'unit_test'
