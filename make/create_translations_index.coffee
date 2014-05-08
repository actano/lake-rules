#!/usr/bin/env coffee

path = require 'path'

manifestPath = process.argv[2]

if not manifestPath
    console.log "\n\nusage: #{path.basename __filename} Manifest.coffee\n\n"
    process.exit 1

manifest = require path.resolve manifestPath

if not manifest.client.translations
    throw new Error("missing client.translations entry in #{manifestPath}")

for code, file of manifest.client.translations
    manifest.client.translations[code] = file.substr(0, file.lastIndexOf('.'))

languageCodes = Object.keys(manifest.client.translations)

console.log """
    var languageCodeFiles = #{JSON.stringify(manifest.client.translations)};
    module.exports.availableLanguages = function() {return #{JSON.stringify(languageCodes)};}
    module.exports.getPhrases = function(languageCode) {return require("../" + languageCodeFiles[languageCode]);}
"""
