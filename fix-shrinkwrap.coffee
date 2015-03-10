fs = require 'fs'
{resolve} = require 'path'
url = require 'url'

file = process.argv[2]

unless file
    console.log "usage: #{process.argv[1]} <file>"
    process.exit 1

fixDeps = (name, node) ->
    # Delete unnecessary from property
    delete node.from if node.from?

     # don't remove node.resolved. will work if module is in cache, won't work if not
    if node.resolved?
        resolved = url.parse node.resolved

        # do the esprima harmony thing
        if resolved.host == 'github.com' && node.version.substr(-8) == '-harmony' && resolved.pathname.substr(-4) == '.git'
            node.version = node.version.substring 0, node.version.length - 8

            resolved.protocol = 'https:'
            resolved.pathname = "#{resolved.pathname.substring(0, resolved.pathname.length - 4)}/tarball/harmony/v#{node.version}"
            resolved.hash = null

            node.resolved = url.format resolved

    deps = node.dependencies
    if deps?
        keys = Object.keys deps
        keys.sort()
        node.dependencies = {}
        for k in keys
            node.dependencies[k] = fixDeps k, deps[k]
    return node

shrinkwrapFile = require resolve file

fixDeps null, shrinkwrapFile

fs.writeFileSync file, JSON.stringify shrinkwrapFile, null, 2
