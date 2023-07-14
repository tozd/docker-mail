# tozd/mail

**WORK IN PROGRESS**

<https://gitlab.com/tozd/docker/mail>

Available as:

- [`tozd/mail`](https://hub.docker.com/r/tozd/mail)
- [`registry.gitlab.com/tozd/docker/mail`](https://gitlab.com/tozd/docker/mail/container_registry)

## Description

Image extending [tozd/postfix](https://gitlab.com/tozd/docker/postfix) image to provide
a full-fledged e-mail service with virtual users.

You should make sure you mount all volumes (especially `/srv/mail`) so that you do not lose e-mails and other
data when you are recreating a container. If volumes are empty, image will initialize them at the first startup.

Integrated services:

- [tozd/postfix](https://gitlab.com/tozd/docker/postfix) – sending and receiving e-mails, extends the image
- [tozd/sympa](https://gitlab.com/tozd/docker/sympa) – mailing lists, runs alongside the image
- [tozd/postfixadmin](https://gitlab.com/tozd/docker/postfixadmin) – virtual users, runs alongside the image
- [Amavis](https://www.ijs.si/software/amavisd/) – interface for virus and spam scanning
- [Clamav](http://www.clamav.net/) – antivirus engine
- [SpamAssassin](https://spamassassin.apache.org/) – anti-spam platform
- [Postgrey](http://postgrey.schweikert.ch/) – greylisting
- [Dovecot](http://www.dovecot.org/) – IMAP and POP3 server

The intended use of this image is that it is extended to provide necessary configuration files and customizations
for your installation, and used together with `tozd/sympa` and `tozd/postfixadmin`.
You can use [tozd/postgresql](https://gitlab.com/tozd/docker/postgresql)
PostgreSQL database.
You might find [tozd/external-ip](https://gitlab.com/tozd/docker/external-ip) Docker image useful, too.

**The image cannot run without extending (or mounting necessary files into it).**

Besides various data volumes they are configuration volumes you have to mount:

- `/config` is a volume which should provide all sensitive and custom configurations for services
- `/etc/postfixadmin/shared` is a volume shared with `tozd/postfix` container to provide necessary SSH keys for communication between containers
- `/etc/sympa/shared` is a volume shared with `tozd/sympa` container to get necessary SSH keys for communication between containers

`/config` volume should contain files:

- `/config/amavis/50-user` – Amavis configuration, the best place to configure your hostname, local domains, and spam handling
- `/config/dovecot/`
  - `connect.conf` – should contain only PostgreSQL `connect` configuration parameter
  - `local.conf` – hostname, postmaster address, and paths to your SSL keys (probably the best is to store them in `/config/ssl`)
- `/config/postfix/`
  - `main.cf.append` – if it exists, it is appended to the `main.cf`
  - `master.cf.append` – if it exists, it is appended to the `master.cf`
- `/config/postfixadmin/pgpass` – PostgreSQL password in the [password file format](http://www.postgresql.org/docs/9.3/static/libpq-pgpass.html),
  used by the `postfixadmin-mailbox-postcreation.sh` script
- `/config/postgrey/`
  - `whitelist_clients.local` – list of extra whitelisted clients
  - `whitelist_recipients.local` – list of extra whitelisted recipients
  - `run.config` – is run at the beginning of Postfix startup, use it to further configure Postfix and run `postmap` on files
  - `run.initialization` – is run just before Postfix process itself is started, possibly use to fix any file permissions
- `/config/spamassassin/local.cf` – you probably want to set `trusted_networks` and `internal_networks` to `172.17.0.0/16`, and configure things like
  Bayes; you can set `bayes_store_module Mail::SpamAssassin::BayesStore::PgSQL` to use a PostgreSQL database for Bayes learning, configure access to it,
  and initialize it using `/usr/share/doc/spamassassin/sql/bayes_pg.sql`

In your `main.cf.append` you probably want to configure virtual users and PostgreSQL database access. Something similar
to:

```
virtual_alias_maps =
  proxy:pgsql:/config/postfix/pgsql_virtual_alias_maps.cf,
  proxy:pgsql:/config/postfix/pgsql_virtual_alias_domain_maps.cf,
  proxy:pgsql:/config/postfix/pgsql_virtual_alias_domain_catchall_maps.cf,
  regexp:/config/postfix/sympa_rewrite
virtual_minimum_uid = 120
virtual_uid_maps = static:120
virtual_gid_maps = static:120
virtual_mailbox_base = /srv/mail/domains
virtual_mailbox_domains = proxy:pgsql:/config/postfix/pgsql_virtual_domains_maps.cf
virtual_mailbox_limit = 0
virtual_mailbox_maps =
  proxy:pgsql:/config/postfix/pgsql_virtual_mailbox_maps.cf,
  proxy:pgsql:/config/postfix/pgsql_virtual_alias_domain_mailbox_maps.cf,
  regexp:/config/postfix/sympa_transport
virtual_transport = dovecot
dovecot_destination_recipient_limit = 1
relay_domains = proxy:pgsql:/config/postfix/pgsql_relay_domains_maps.cf
```

See [full documentation](https://github.com/postfixadmin/postfixadmin/blob/master/DOCUMENTS/POSTFIX_CONF.txt) on how
to configure Postfix with Postfix Admin (`tozd/postfixadmin`).

The `/etc/sympa/shared` volume should contain also `sympa_rewrite` and `sympa_transport` files configuring the mailing
lists which exist.

Example of a `sympa_rewrite` file:

```
/^sympa-request@/	postmaster
/^sympa-owner@/		postmaster
/(.+)-owner@(.+)/	$1+owner@$2
```

Example of a `sympa_transport` file, for each domain you have Sympa providing mailing lists:

```
/^sympa@example\.com$/	 sympadomain:
/^abuse-feedback-report@example\.com$/	 sympabouncedomain:
/^bounce\+.*@example\.com$/	 sympabouncedomain:
/^listmaster@example\.com$/	 sympa:
/^.+(announce|list|info|event|press|talk|news)\+owner@example\.com$/	sympabounce:
/^.+(announce|list|info|event|press|talk|news)(-request|-editor|-subscribe|-unsubscribe)?@example\.com$/	sympa:
```
