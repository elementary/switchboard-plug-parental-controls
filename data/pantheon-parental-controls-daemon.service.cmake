[Unit]
Description=Pantheon Parental Controls Daemon

[Service]
Type=simple
ExecStart=/bin/bash -c "sudo @CMAKE_INSTALL_PREFIX@/bin/pantheon-parental-controls-daemon"

[Install]
WantedBy=default.target
