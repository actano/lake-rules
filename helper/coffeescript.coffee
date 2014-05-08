path = require 'path'

fs = require './filesystem'

module.exports.addCoffeeRule = (ruleBook, src, dst) ->
    dst = fs.replaceExtension(dst, '.js')
    switch path.extname src
        when '.coffee'
            dstPath = fs.addMkdirRule ruleBook, path.dirname dst
            ruleBook.addRule dst, [], ->
                targets: dst
                dependencies: [src, '|', dstPath]
                actions: "$(COFFEEC) $(COFFEE_FLAGS) --compile --output #{dstPath} $^"
        when '.js'
            fs.addCopyRule ruleBook, src, dst
    return dst
