#!/bin/sh
# Script for running scripts for managing Postfix.
#
# Author: GW <gw.2009@tnode.com>
# Version: 0.1

SCRIPTS_PATH='/etc/postfixadmin/scripts'
SCRIPTS='postfixadmin-domain-postcreation.sh postfixadmin-domain-postdeletion.sh postfixadmin-mailbox-postcreation.sh postfixadmin-mailbox-postdeletion.sh'

if echo "$SSH_ORIGINAL_COMMAND" | egrep -q '[^0-9A-Za-z \._/@+-]' || echo "$SSH_ORIGINAL_COMMAND" | egrep -q ' /|\.\./'; then
	exit 2
fi

command=`echo "$SSH_ORIGINAL_COMMAND" | cut -d ' ' -f 1`

for script in $SCRIPTS; do
	if [ "$command" = "$script" ]; then
		cd "$SCRIPTS_PATH"
		"$SCRIPTS_PATH"/$SSH_ORIGINAL_COMMAND
		exit $?
	fi
done

exit 1
