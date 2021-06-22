# Switchboard Parental Controls Plug
[![Translation status](https://l10n.elementary.io/widgets/switchboard/-/switchboard-plug-parental-controls/svg-badge.svg)](https://l10n.elementary.io/engage/switchboard/?utm_source=widget)

![screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libaccountsservice-dev
* libdbus-1-dev
* libglib2.0-dev
* libgranite-dev
* libpolkit-gobject-1-dev
* libswitchboard-2.0-dev
* libflatpak-dev
* libmalcontent-0-dev
* meson >= 0.46.1
* policykit-1
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
