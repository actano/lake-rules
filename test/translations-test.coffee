translationsRules = require '../make/translations'
{executeRule, globals} = require './rule-test-helper'
{expect} = require 'chai'

describe 'translations rule', ->
    it 'should create rules for client.translations', (done) ->
        manifest =
            client:
                translations:
                    'de_DE':    'path/de_WURST.coffee'
                    'en_US':    'path/en_UK.coffee'

        targets = executeRule translationsRules, {}, manifest
        _build = (script) ->  "#{globals.lake.featureBuildDirectory}/#{globals.featurePath}/#{script}"

        expect(targets).to.have.property(_build "translations")
        expect(targets).to.have.property(_build "translations/index.js")
        expect(targets[_build "translations/index.js"].dependencies).to.match(/Manifest.coffee/)

        _expectCoffeeRule = (dst) ->
            expect(targets).to.have.property(_build dst)
            expect(targets[_build dst].dependencies).to.match(
                new RegExp "#{dst.substr(0,dst.lastIndexOf('.'))}.coffee")

        _expectCoffeeRule("path/de_WURST.js")
        _expectCoffeeRule("path/en_UK.js")

        done()



