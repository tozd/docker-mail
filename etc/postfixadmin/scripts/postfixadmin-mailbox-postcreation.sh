#!/bin/sh

### Author: nejc@skoberne.net
# PgSQL support by GW <gw.2010@tnode.com or http://gw.tnode.com/>

### Description
# This script creates or updates the aliases which point to all the mailboxes
# ("everybody aliases") for all active domains. Also, it can create the "big
# everybody alias" which points to all the "everybody aliases" of all the
# domains and is created for the MASTERDOMAIN domain.

### Configuration
# Create the "big everybody alias" (alias of all other aliases) for this domain
# Leave this empty if you don't want to create/update the big alias
MASTERDOMAIN="common.tnode.com"
# The name of the alias which will point to all of the mailboxes for each domain
ALIAS="vsiskupaj"
# The name of the big alias which will point to all the aliases ($ALIAS)
BIGALIAS="resvsiskupaj"
# Mailboxes to always skip (separated by space, with or without domain name)
MAILBOXSKIP="admin"

### Database configuration
# Supported types: mysql, pgsql
DBTYPE="pgsql"
# Hostname where your database server is running
HOST="dbpgsql"
# Name of database (e.g. postfixadmin)
DATABASE="system"
# Leave empty when using MySQL and enter optional PgSQL schema ending with a dot
SCHEMA="postfixadmin."
# For password login in MySQL put the password in your `~/.my.conf`
# For password login in PgSQL put the password into a file referenced by PGPASSFILE
# with format: hostname:port:database:username:password
export PGPASSFILE="/config/postfixadmin/pgpass"

### Auxiliary variables
if [ "$DBTYPE" = "mysql" ]; then
	DBCMD="/usr/bin/mysql -h $HOST $DATABASE"
	BOOLTRUE="1"
	BOOLFALSE="0"
else
	DBCMD="/usr/bin/psql -h $HOST $DATABASE"
	BOOLTRUE="true"
	BOOLFALSE="false"
fi
check2="false"
merged2="false"

### Program code
# Loop through all the active non-backupmx domains ...
for domain in `echo "SELECT domain FROM ${SCHEMA}domain WHERE backupmx=$BOOLFALSE AND active=$BOOLTRUE;" | $DBCMD | grep '\.'`
do
  # Delete old alias first
  echo "DELETE FROM ${SCHEMA}alias WHERE address='$ALIAS@$domain';" | $DBCMD

  # Auxiliary variables
  check="false"
  merged=""
  address=""

  # Loop through all the active mailboxes for each domain
  for address in `echo "SELECT username FROM ${SCHEMA}mailbox WHERE domain='$domain' AND active=$BOOLTRUE;" | $DBCMD | grep '@'`
  do
    # Skip some mailboxes
    skipit="false"
    for skip in $MAILBOXSKIP
    do
      if echo "$skip" | grep "@$domain"
      then
        if echo "$skip" | grep "$address@$domain"
        then
          skipit="true"
        fi
      else
        if echo "$skip@$domain" | grep "$address@$domain"
        then
          skipit="true"
        fi
      fi
    done

    if [ "$skipit" = "true" ]
    then
      continue
    fi

    # Add the address to the list of addresses
    if [ "$check" = "false" ]
    then
      merged="$address"
    else
      merged="$merged,$address"
    fi
    check="true"
  done

  # If the address list is empty, skip this domain
  if [ "$merged" = "" ]
  then
    continue
  fi

  # Insert the new alias into the database
  echo "INSERT INTO ${SCHEMA}alias (address,goto,domain,active) VALUES ('$ALIAS@$domain','$merged','$domain',$BOOLTRUE);" | $DBCMD

  # Add the new alias to the list of all new aliases for the big alias
  if [ "$check2" = "false" ]
  then
    merged2="$ALIAS@$domain"
  else
    merged2="$merged2,$ALIAS@$domain"
  fi
  check2="true"
done

# Delete the old big alias first
echo "DELETE FROM ${SCHEMA}alias WHERE address='$BIGALIAS@$MASTERDOMAIN';" | $DBCMD

# If the new big alias is not empty ...
if [ ! "$merged2" = "" ] && [ ! "$merged2" = "false" ]
then
  # ... insert it into the database
  echo "INSERT INTO ${SCHEMA}alias (address,goto,domain,active) VALUES ('$BIGALIAS@$MASTERDOMAIN','$merged2','$MASTERDOMAIN',$BOOLTRUE);" | $DBCMD
fi

