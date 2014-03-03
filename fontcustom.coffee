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
    # lib/foobar/build
    buildPath = path.join featurePath, lake.featureBuildDirectory
    # lib/foobar/build/icons
    iconPath = path.join featurePath, 'icons'

    projectRoot = path.resolve lake.lakePath, ".." # project root


    if manifest.client?.fonts?
     
        extensions = [
            'eot'
            'svg'
            'ttf'
            'woff'
            'css'
        ]

        for font in manifest.client.fonts
            sourcePath = path.join featurePath, font.name
            fontBuildPath = path.join buildPath, 'fonts', font.name
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

  

            rb.addRule "fontcustom: #{featurePath}-#{font.name}", ["client", 'feature'], ->
                #targets: ("#{path.join buildPath, font}.#{e}" for e in extensions)
                targets: path.join fontBuildPath, ".fontcustom-manifest.json"
                dependencies: tmpSvgs

                actions: [
                    "cd #{tempSVGPath} && /bin/bash -O extglob -c \"rm !(#{svgs.join '|'})\" && cd -"
                    "mkdir -p #{fontBuildPath}"
                    "cd #{fontBuildPath} && fontcustom compile #{path.relative fontBuildPath, tempSVGPath} --no-hash --font-name=#{font.name} --output=."
                ]


