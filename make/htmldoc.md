## Htmldoc lake rules

### Abstract

These rules generate the HTML documentation of RPLAN X. The documentation is available in the application itself as
well as a standalone static web page.

It is composed of multiple subpages where each subpage corresponds to a feature in the lib/ directory. The subpages
are written in Markdown and transformed to HTML with Docpad.

### Main targets

    htmldoc
    htmldoc/clean

### Manifest

	documentation: [<markdown.file>, ...]

Markdown files named 'Readme.md' are treated special. The HTML output of 'Readme.md' will be the main part of the
documentation for the specific feature.