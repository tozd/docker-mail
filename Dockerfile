FROM tozd/postfix

RUN apt-get update -q -q && \
 apt-get install adduser openssh-server openssh-client postfix-pgsql postfix-doc amavisd-new altermime apt-listchanges \
  arj cabextract clamav-daemon cpio lhasa libmail-dkim-perl libdbd-pg-perl lzop nomarch p7zip ripole rpm \
  spamassassin unrar-free zoo bzip2 libio-socket-ssl-perl postgrey dovecot-imapd dovecot-pop3d \
  dovecot-managesieved dovecot-pgsql dovecot-sieve --yes --force-yes && \
 adduser --system --group mailpipe --no-create-home --home /nonexistent && \
 addgroup --gid 120 vmail && \
 adduser --system --ingroup vmail --uid 120 --gecos "Virtual email user" --home /srv/mail --shell /bin/sh vmail && \
 cp /etc/postfix/main.cf /etc/postfix/main.cf.orig && \
 cp /etc/postfix/master.cf /etc/postfix/master.cf.orig && \
 sed -r -i 's/^UpdateLogFile/#UpdateLogFile/' /etc/clamav/freshclam.conf && \
 sed -r -i 's/^LogFile/#LogFile/' /etc/clamav/clamd.conf

COPY ./etc /etc
