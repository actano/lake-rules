#!/usr/bin/env coffee
fs = require 'fs'
path = require 'path'
{features, resolveManifest, getManifest} = require './lake/config'

hasConflicts = false
scriptsMainSectionConflict = []

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
    for feature in features
        manifestPath = resolveManifest feature
        manifest = getManifest feature

        clientScriptsMainChecker manifestPath, manifest

    if hasConflicts
        process.exit 1

checkManifests()
