#!/bin/sh

# Restart Amavis so that local domain list is reloaded.
# "restart" is our wrapper script for restarting Amavis.
sudo /etc/service/amavis/restart

exit $?
