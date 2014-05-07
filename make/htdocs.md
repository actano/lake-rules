## feature local browser test

### abstract

the rule builds feature local test html files for manual browser tests

### main targets

creating the html files from jade teamplates

    featurePath/htdocs
    htdocs

### Manifest.coffee

    manifest.coffee:
        client:
            htdocs:
                html: 'jade.file'
                dependencies: [<jade.includes>]


the jade file is compiled to a html file in the build directory at the same location.
the relative location of the component build directory (componentDir) is passed to the jade template.
the optional dependencies are make prerequisites of the target.


