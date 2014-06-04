# HtmlDoc

## Abstract

Generate HTML documentation of RPLAN X. The documentation is available in the application itself as
well as a standalone, static web page.

It is composed of multiple subpages where each subpage corresponds to a feature
in the `lib/` directory. The subpages are written in Markdown and transformed to
HTML with Docpad.

## Targets

- `htmldoc` generates the documentation
- `htmldoc/clean` removes generated files

## Manifest

    manifest.coffee
        documentation: [<markdown.file>, ...]

Markdown files named 'Readme.md' are treated special. The HTML output of 'Readme.md' will be the main part of the
documentation for the given feature.
