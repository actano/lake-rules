# Std library
path = require 'path'
fs = require 'fs'

# Local dep
{replaceExtension, concatPaths} = require "./rulebook_helper"

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
                    "mkdir -p #{fontBuildPath}"
                    "mkdir -p #{buildPath}/fonts"
                    "cd #{fontBuildPath} && fontcustom compile #{path.relative fontBuildPath, tempSVGPath} --templates css preview #{path.relative tempSVGPath, 'tools/rules/codepoints.styl'} --css-selector='.fa-{{glyph}}' --no-hash --font-name=#{font.name} --output=."
                ]

            for file in fontFiles
                do (file) ->
                    rb.addRule file, ['component-build-prerequisite', 'add-to-component-fonts'], ->
                        targets: [path.join "#{buildPath}/fonts", file]
                        dependencies: [fontManifest]
                        actions: [
                            "cp #{path.join fontBuildPath, file} #{path.join buildPath, 'fonts', file}"
                        ]

            for file in cssFiles
                do (file) ->
                    rb.addRule file, ['component-build-prerequisite', 'add-to-component-styles'], ->
                        targets: [path.join "#{buildPath}/fonts", file]
                        dependencies: [fontManifest]
                        actions: [
                            "cp #{path.join fontBuildPath, file} #{path.join buildPath, 'fonts', file}"
                        ]







