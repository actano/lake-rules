Promise = require 'bluebird'
path = require 'path'
{readFile, writeFile} = require '../helper/fileutils'

pathComparator = (a, b) ->
    return 0 if a is b

    da = path.dirname a
    db = path.dirname b
    c = da.localeCompare db
    return c unless c is 0

    a = path.basename a
    return -1 if a is 'index.html'

    b = path.basename b
    return 1 if b is 'index.html'

    return a.localeCompare b

markdown = Promise.coroutine (target, title, content = '') ->
    marked = Promise.promisify require 'marked'
    unless '' is content
        content = content.replace /^#/gm, '##'
        content = yield marked content, headerPrefix: "#{title}/".replace /[/.]/g, '-'

    prefix = yield marked "# #{title}"
    writeFile target, prefix + content

module.exports =
    'htmldoc-index': Promise.coroutine (target, dir, readme) ->
        content = unless '' is readme then yield readFile readme else ''
        yield markdown target, dir, content
        return 0

    'htmldoc-markdown': Promise.coroutine (target, src, title = src) ->
        title = src if title.trim() is ''
        srcContent = yield readFile src
        yield markdown target, title, srcContent
        return 0

    'htmldoc-result': Promise.coroutine (target, src) ->
        jade = require 'jade'
        src = src.split ' '
        src.sort pathComparator
        promises = []
        src.map (snippet) ->
            src = readFile snippet
            if '.jade' is path.extname snippet
                promises.unshift src
            else
                promises.push src

        snippetContents = yield Promise.all promises
        template = snippetContents.shift()
        html = jade.render template,
            snippets: snippetContents
        writeFile target, html
        return 0

    'htmldoc-feature': Promise.coroutine (target, src) ->
        contents = ''
        unless src is ''
            src = src.split ' '
            src.sort pathComparator
            contents = yield Promise.all src.map (f) -> readFile f
            contents = contents.join ''
        writeFile target, contents
        return 0


