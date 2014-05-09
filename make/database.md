# Database

## Abstract

Generates rules for installing CouchBase views.

## Targets

- `featurePath/couchview` installs the views of the given feature
- `couchview` installs views across all features

## Manifest

Views are specified in the "database.designDocuments" section. They can be
either be CoffeeScript or Javascript files. CoffeeScript files are first
compiled to Javascript while Javascript files are used directly.

    manifest.coffee
        database:
            designDocuments: [<view.js>, <view.coffee>, ...]
