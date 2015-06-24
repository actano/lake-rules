Promise = require 'bluebird'
mkdirp = Promise.promisify require 'mkdirp'
path = require 'path'
fs = Promise.promisifyAll require 'fs'

readFile = (src, encoding = 'utf-8') ->
    return fs.readFileAsync src, encoding

writeFile = (dst, contents, encoding = 'utf-8') ->
    mkdirp path.dirname dst
        .then -> fs.writeFileAsync dst, contents, encoding: encoding

module.exports = {
    readFile
    writeFile
    mkdirp
}