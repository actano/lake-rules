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
