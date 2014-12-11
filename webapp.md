# WebApp

## Abstract

Generates rules to build the web app. Specialized for the `lib/webapp` feature.

## Targets

- `featurePath/widgets` installs widgets (main components)
- `featurePath/menus` installs menus
- `featurePath/install` installs the given feature into the runtime directory
- `install` installs all features to the runtime directory

## Manifest

Webapp specific entries are located in the section "webapp".

Widgets (main components) are specified in "webapp.widgets" and list other
local features which should be installed.

REST APIs are specified in "webapp.restApis" and will be installed as well.

Menus are given as key-value pairs in "webapp.menu".

    manifest.coffee
        webapp:
            widgets: ['../featureA', '../featureB']
            restApis: ['../featureC', '../featureD']
            menu:
                name: '../featureE'
