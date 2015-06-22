translationsRules = require '../translations'
{executeRule, globals} = require './rule-test-helper'
{expect} = require 'chai'

_build = (script) ->  "#{globals.featureBuildDirectory}/#{globals.featurePath}/#{script}"

describe 'translations rule', ->
    it 'should create rules for client.translations', ->
        manifest =
            client:
                translations:
                    'de_DE':    'path/de_WURST.coffee'
                    'en_US':    'path/en_UK.coffee'

        targets = executeRule translationsRules, {}, manifest

        expect(targets).to.have.property(manifest._build "translations")
        expect(targets).to.have.property(manifest._build "translations/index.js")
        expect(targets[manifest._build "translations/index.js"]).to.depend(/Manifest.coffee/)

        _expectCoffeeRule = (dst) ->
            expect(targets).to.have.property(manifest._build dst)
            expect(targets[manifest._build dst]).to.depend(
                new RegExp "#{dst.substr(0,dst.lastIndexOf('.'))}.coffee")

        _expectCoffeeRule("path/de_WURST.coffee")
        _expectCoffeeRule("path/en_UK.coffee")
