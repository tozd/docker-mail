#!/bin/bash -e
#
# Script for running scripts for managing Postfix.

SCRIPTS_PATH='/etc/postfixadmin/scripts'
SCRIPTS='postfixadmin-domain-postcreation.sh postfixadmin-domain-postdeletion.sh postfixadmin-mailbox-postcreation.sh postfixadmin-mailbox-postdeletion.sh'

command=$(echo "$SSH_ORIGINAL_COMMAND" | cut -d ' ' -f 1)
args=$(echo "$SSH_ORIGINAL_COMMAND" | cut -s -d ' ' -f 2-)

for script in $SCRIPTS; do
  if [ "$command" = "$script" ]; then
    cd "$SCRIPTS_PATH"
    exec "${SCRIPTS_PATH}/${command}" $args
    # From now on it is another process.
  fi
done

exit 1
