Promise = require 'bluebird'

module.exports =
    couchview: Promise.coroutine (target, src) ->
        couchbase = require "#{target}/lib/couchbase"
        bucket = couchbase.getBucket()
        yield bucket.uploadDesignDocAsync src
        return 0
