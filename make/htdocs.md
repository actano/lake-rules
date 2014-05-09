# htdocs

## abstract

Generates HTML files for manual browser tests.

## main targets

- `featurePath/htdocs` generates test files for the specified feature
- `htdocs` generates test files across all features

## Manifest.coffee

    manifest.coffee:
        client:
            htdocs:
                html: 'jade.file'
                dependencies: [<jade.includes>]


The Jade file is compiled to a HTML file in the build directory at the same
location.  The relative location of the component build directory (componentDir)
is passed to the Jade template.  Optional dependencies are make prerequisites of
the target.
