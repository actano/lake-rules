#!/usr/bin/env coffee
fs = require 'fs'
path = require 'path'
lakeConfig = require './lake/config'

hasConflicts = false
componentMap = {}
scriptsMainSectionConflict = []

# we don't need this anymore, because component 1 can handle semver and multiple versions of the same dependency
captureDependencies = (manifestPath, deps) ->
    for dep, version of deps
        continue if version is '*'
        componentMap[dep] ?= {}
        componentMap[dep][version] ?= []
        componentMap[dep][version].push manifestPath


dependencyChecker = (manifestPath, manifest) ->
    return unless manifest.client?.dependencies?

    if manifest.client.dependencies.production?.remote?
        captureDependencies manifestPath, manifest.client.dependencies.production.remote

    if manifest.client.dependencies.development?.remote?
        captureDependencies manifestPath, manifest.client.dependencies.development.remote


dependencyCheckerResolveConflicts = ->
    for component, info of componentMap
        if Object.keys(info).length > 1
            console.log "multiple versions for components: '#{component}'"
            for version, files of info
                console.log "  -> found version '#{version}'"
                for file in files
                    console.log "    in #{file}"


clientScriptsMainChecker = (manifestPath, manifest) ->
    return unless manifest.client?
    hit = 0
    hit++ if manifest.client.scripts?
    hit++ if manifest.client.main?
    if hit is 1
        hasConflicts = true
        scriptsMainSectionConflict.push manifestPath
        console.log "conflict missing client.scripts or client.main section in #{manifestPath}"


checkManifests = ->
    config = lakeConfig.config()
    features = config.features
    for feature in features
        manifestPath = config.resolveManifest feature
        manifest = config.getManifest feature

        dependencyChecker manifestPath, manifest
        clientScriptsMainChecker manifestPath, manifest

    dependencyCheckerResolveConflicts()

    if hasConflicts
        process.exit 1

checkManifests()
