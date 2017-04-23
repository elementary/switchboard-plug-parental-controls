# Switchboard Parental Controls Plug
[![Translation status](https://l10n.elementary.io/widgets/switchboard/switchboard-plug-parental-controls/svg-badge.svg)](https://l10n.elementary.io/projects/switchboard/switchboard-plug-parental-controls/?utm_source=widget)

## Building, Testing, and Installation

You'll need the following dependencies:
* cmake
* dh-systemd
* libaccountsservice-dev
* libglib2.0-dev
* libgranite-dev
* libpolkit-gobject-1-dev
* libswitchboard-2.0-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`, then execute with `switchboard`

    sudo make install
    switchboard
