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


    if manifest.client?.fontsource?

        extensions = [
            'eot'
            'svg'
            'ttf'
            'woff'
        ]

        for font in manifest.client.fontsource
            sourcePath = path.join featurePath, font.name
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

            rb.addRule "fontcustom: #{featurePath}-#{font.name}", ["client", 'feature'], ->
                #targets: ("#{path.join buildPath, font}.#{e}" for e in extensions)
                targets: path.join fontBuildPath, ".fontcustom-manifest.json"
                dependencies: tmpSvgs
                actions: [
                    "cd #{tempSVGPath} && find . ! -name #{svgs.join(' ! -name ')} -type f -maxdepth 1 -delete && cd -"
                    # TODO: find out why rm !(a|b|c) only accepts three pattern on ubuntu while on mac os x it takes infinte
                    #"cd #{tempSVGPath} && /bin/sh -O extglob -c \"rm !(#{svgs.join('|')})\" && cd -"
                    "mkdir -p #{fontBuildPath}"
                    "mkdir -p #{buildPath}/fonts"
                    "cd #{fontBuildPath} && fontcustom compile #{path.relative fontBuildPath, tempSVGPath} --css-selector='.{{glyph}}' --no-hash --font-name=#{font.name} --output=."
                    "cd #{fontBuildPath} && cp *.ttf *.eot *.svg *.woff *.css #{path.relative fontBuildPath,buildPath}/fonts"
                ]

            componentContent =
                name: 'iconfont'
                description: 'customfont'
                version: '0.0.1'
                license: 'MIT'
                keywords: []
                dependencies: {},
                development: {},
                styles: [ "fonts/#{font.name}.css"]
                fonts: ("fonts/#{font.name}.#{ext}" for ext in extensions)

            localComponentPath = path.join lake.localComponentsPath, featurePath

            componentDependencies = (path.join buildPath, "fonts", "#{font.name}.#{ext}" for ext in extensions)

            componentDependencies.unshift path.join buildPath, 'fonts',"#{font.name}.css"
            componentDependencies.unshift path.join fontBuildPath, ".fontcustom-manifest.json"

            rb.addRule "component.json", ["client"], ->
                targets: path.join buildPath, "component.json"
                dependencies: componentDependencies
                actions: [
                    "echo '#{JSON.stringify(componentContent, null)}' > #{buildPath}/component.json"
                    "mkdir -p #{localComponentPath}/fonts"
                    "cp -fp #{path.join buildPath, 'fonts', '*'} #{path.join localComponentPath,'fonts'}/"
                ]




