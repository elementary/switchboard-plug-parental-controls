# Switchboard Parental Controls Plug
[![l10n](https://l10n.elementary.io/widgets/switchboard/switchboard-plug-parental-controls/svg-badge.svg)](https://l10n.elementary.io/projects/switchboard/switchboard-plug-parental-controls)

## Building and Installation

You'll need the following dependencies:

* libaccountsservice-dev
* libdbus-1-dev
* libglib2.0-dev
* libgranite-dev
* libpolkit-gobject-1-dev
* libswitchboard-2.0-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
