#!/bin/sh

# Example script for removing a Maildir domain top-level folder
# from a Courier-IMAP virtual mail hierarchy.

# The script only looks at argument 1, assuming that it 
# indicates the relative name of a domain, such as
# "somedomain.com". If $basedir/somedomain.com exists, it will
# be removed.

# The script will not actually delete the directory. I moves it
# to a special directory which may once in a while be cleaned up
# by the system administrator.

# This script should be run as the user which owns the maildirs. If 
# the script is actually run by the apache user (e.g. through PHP),
# then you could use "sudo" to grant apache the rights to run
# this script as the relevant user.
# Assume this script has been saved as
# /usr/local/bin/postfixadmin-domain-postdeletion.sh and has been
# made executable. Now, an example /etc/sudoers line:
# apache ALL=(courier) NOPASSWD: /usr/local/bin/postfixadmin-domain-postdeletion.sh
# The line states that the apache user may run the script as the
# user "courier" without providing a password.


# Change this to where you keep your virtual mail users' maildirs.
basedir=/srv/mail/domains

# Change this to where you would like deleted maildirs to reside.
trashbase=/srv/mail/trash

if [ `echo $1 | fgrep '..'` ]; then
  echo "First argument contained a double-dot sequence; bailing out."
  exit 1
fi

if [ ! -e "$trashbase" ]; then
  echo "trashbase '$trashbase' does not exist; bailing out."
  exit 1
fi

# Restart Amavis so that local domain list is reloaded.
# "restart" is our wrapper script for restarting Amavis.
sudo /etc/service/amavis/restart

trashdir="${trashbase}/`date +%F_%T`_$1"
domaindir="${basedir}/$1"

if [ ! -e "$domaindir" ]; then
  echo "Directory '$domaindir' does not exits; nothing to do."
  exit 0;
fi
if [ ! -d "$domaindir" ]; then
  echo "'$domaindir' is not a directory; bailing out."
  exit 1
fi
if [ -e "$trashdir" ]; then
  echo "Directory '$trashdir' already exits; bailing out."
  exit 1;
fi

mv "$domaindir" "$trashdir"

/etc/postfixadmin/scripts/postfixadmin-mailbox-postcreation.sh

exit $?
