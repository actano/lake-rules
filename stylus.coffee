# Std library
path = require 'path'
fs = require 'fs'

# Local dep
{replaceExtension, concatPaths} = require "./rulebook_helper"

exports.title = 'stylus'
exports.description = "convert stylus to css"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    # lib/foobar/build
    buildPath = path.join featurePath, lake.featureBuildDirectory
    # lib/foobar/build/styles
    stylePath = path.join featurePath, 'styles'
    styluesBuildPath = path.join buildPath, 'styles'

    projectRoot = path.resolve lake.lakePath, ".." # project root


    if manifest.client?.styles?

        importedFiles = concatPaths manifest.client.styles, {pre: featurePath}, (file) ->
            scanForImports projectRoot, stylePath, file

        rb.addRule "stylus", ["client"], ->
            targets: concatPaths manifest.client.styles, {pre: buildPath}, (file) ->
                replaceExtension file, '.css'
            dependencies: [
                concatPaths manifest.client.styles, {pre: featurePath}
                importedFiles
            ]
            actions: [
                "mkdir -p #{styluesBuildPath}"
                "$(STYLUSC) $(STYLUS_FLAGS) -o #{styluesBuildPath} $^"
            ]

IMPORT_PATTERN = /^@import\s*['"](.*)["']/

scanForImports = (projectRoot, stylePath, file) ->
    input = fs.readFileSync(path.join projectRoot, file).toString().trim()
    importedFiles = []
    for line in input.split('\n')
        matches = line.match IMPORT_PATTERN
        if matches?.length > 0
            try
                importedFile = matches[1]
                if importedFile.substr(0, 5) isnt '../..'
                    continue
                importedFile = path.resolve stylePath, importedFile
                #console.log importedFile
                importedFiles.push importedFile
            catch err
                console.error 'Could not parse "@import" from stylus'
                console.error err.message
                throw err
    importedFiles
