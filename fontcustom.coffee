# Std library
path = require 'path'
fs = require 'fs'

# Local dep
{replaceExtension} = require "./helper/filesystem"

exports.title = 'fontcustom'
exports.description = "convert svgs to web fonts"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    # build/lib/foobar
    buildPath = path.join lake.featureBuildDirectory, featurePath

    if manifest.client?.fontsource?

        extensions = [
            'eot'
            'svg'
            'ttf'
            'woff'
        ]

        for font in manifest.client.fontsource
            fontBuildPath = path.join buildPath, 'fontbuild', font.name
            tempSVGPath = path.join fontBuildPath, 'svgs'

            svgs = []
            tmpSvgs = []

            for glyph in font.glyphs
                src = path.join featurePath, glyph
                dest = path.join tempSVGPath, path.basename glyph
                svgs.push path.basename glyph
                tmpSvgs.push dest
                do (src, dest) ->
                    rb.addRule dest, [], ->
                        targets: dest
                        dependencies: src
                        actions:
                            "mkdir -p #{tempSVGPath} && cp #{src} #{dest}"

            fontFiles = ("#{font.name}.#{ext}" for ext in extensions)
            cssFiles = ["#{font.name}.css"]
            fontManifest = path.join fontBuildPath, ".fontcustom-manifest.json"

            rb.addRule "fontcustom: #{featurePath}-#{font.name}", ["client", 'feature'], ->
                targets: fontManifest
                dependencies: tmpSvgs
                actions: [
                    "cd #{tempSVGPath} && find . ! -name #{svgs.join(' ! -name ')} -type f -maxdepth 1 -delete && cd -"
                    "cp tools/rules/codepoints.styl #{tempSVGPath}"
                    "mkdir -p #{fontBuildPath}"
                    "cd #{fontBuildPath} && fontcustom compile #{path.relative fontBuildPath, tempSVGPath} --templates css preview codepoints.styl --css-selector='.fa-{{glyph}}' --no-hash --font-name=#{font.name} --output=."
                ]

            for file in fontFiles
                do (file) ->
                    rb.addRule file, [], ->
                        targets: [path.join "#{buildPath}/fonts", file]
                        dependencies: [fontManifest]
                        actions: [
                            "@mkdir -p #{buildPath}/fonts"
                            "cp #{path.join fontBuildPath, file} #{path.join buildPath, 'fonts', file}"
                        ]

            for file in cssFiles
                do (file) ->
                    rb.addRule file, [], ->
                        targets: [path.join "#{buildPath}/fonts", file]
                        dependencies: [fontManifest]
                        actions: [
                            "@mkdir -p #{buildPath}/fonts"
                            "cp #{path.join fontBuildPath, file} #{path.join buildPath, 'fonts', file}"
                        ]

module.exports.getTargets = (lake, manifest, tag) ->
    return [] unless manifest.client?.fontsource?

    extensions = [
        'eot'
        'svg'
        'ttf'
        'woff'
    ]
    buildPath = path.join '$(LOCAL_COMPONENTS)', manifest.featurePath

    if tag == 'fonts'
        targets = []
        for font in manifest.client.fontsource
            for ext in extensions
                fontFile = "#{font.name}.#{ext}"
                fontTarget = path.join buildPath, 'fonts', fontFile
                targets.push fontTarget
        return targets
    else if tag == 'styles'
        targets = []
        for font in manifest.client.fontsource
            cssFile = "#{font.name}.css"
            cssTarget = path.join buildPath, 'fonts', cssFile
            targets.push cssTarget
        return targets
    else
        throw new Error("Unknown tag #{tag}")
