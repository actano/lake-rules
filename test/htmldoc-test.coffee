htmldocRule = require '../make/htmldoc'
{executeRule, globals} = require './rule-test-helper'
{expect} = require 'chai'
path = require 'path'

_local = (file) -> path.join globals.featurePath, file
_docpadSrc = (file) -> path.join '$(HTMLDOC)/src', globals.featurePath, file
_docpadOut = (file) -> path.join '$(HTMLDOC)/out', file
_componentBuild = (file) -> path.join globals.featureBuildDirectory, globals.featurePath, 'component-build', file

describe 'htmldoc rules', ->
    it 'should copy docfiles', ->
        manifest =
            documentation: ['foo.md', 'bar.md']

        targets = executeRule htmldocRule, {}, manifest

        expect(targets[_docpadSrc 'foo.html.md']).to.depend _local 'foo.md'
        expect(targets[_docpadSrc 'bar.html.md']).to.depend _local 'bar.md'

    it 'should treat Readme.md specially', ->
        manifest =
            documentation: ['foo.md', 'bar.md', 'Readme.md']

        targets = executeRule htmldocRule, {}, manifest

        expect(targets[_docpadSrc 'index.html.md']).to.depend _local 'Readme.md'

    it 'should create a commit page', ->
        manifest =
            documentation: ['foo.md', 'bar.md']

        targets = executeRule htmldocRule, {}, manifest

        expect(targets[_docpadSrc 'commit.html.md']).to.containAction /git.+log/i

    it 'should add targets to build/htmldoc/out', ->
        manifest =
            documentation: ['foo.md', 'bar.md']

        targets = executeRule htmldocRule, {}, manifest

        expect(targets['$(HTMLDOC)/out']).to.depend [
            _docpadSrc 'foo.html.md'
            _docpadSrc 'bar.html.md'
            _docpadSrc 'commit.html.md'
        ]

    it 'should use the htmldoc component', ->
        manifest =
            name: 'htmldoc'

        targets = executeRule htmldocRule, {}, manifest

        expect(targets[_docpadOut 'htmldoc.js']).to.copy _componentBuild 'htmldoc.js'
        expect(targets[_docpadOut 'htmldoc.css']).to.copy _componentBuild 'htmldoc.css'
        expect(targets['htmldoc']).to.depend [
            _componentBuild 'component-is-build'
            _docpadOut 'htmldoc.js'
            _docpadOut 'htmldoc.css'
        ]
