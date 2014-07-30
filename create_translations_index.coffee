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

# TODO: why using '../translations/xyz' ? go up, then again into translations?
languages = []
for key, val of manifest.client.translations
    languages.push """'#{key}': function() {return require('../#{val}');}"""

template = """
(function () {
  var languages = {
    #{languages.join(',\n  ')}
  };

  module.exports.availableLanguages = function() {
    return Object.keys(languages);
  };

  module.exports.getPhrases = function(languageCode) {
    return languages[languageCode]();
  };
}).call(this);
"""

console.log template
