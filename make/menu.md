# Menu

## Abstract

Creates menu file structure needed by the web app.

## Targets

None of the targets created by this rule file need to be invoked manually. They
are automatically used by the webapp rules.

## Manifest

Each menu definition is specified in a separate key in the section "menus"

    manifest.coffee
        menus:
            name: 'definition.coffee'

The definition must match the structure defined in
'lib/navigation-menu/model-config.coffee'.

Additionally, the menu must be referenced by the web app in section "webapp.menu"
(this is handled by the webapp rule).

    manifest.coffee
        webapp:
            menu:
                name: '../feature'
