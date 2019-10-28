FROM alpine:latest

MAINTAINER Mathieu Donze <mathieu.donze@cern.ch>

#Build the softmodem
COPY fir.h.patch /tmp/
COPY app_softmodem.c.patch /tmp/
RUN apk add --no-cache \
      asterisk-dev \
      spandsp-dev \
      tiff-dev \
      build-base \
&& wget -P /tmp https://raw.githubusercontent.com/proquar/asterisk-Softmodem/app_softmodem/app_softmodem.c \
&& patch /usr/include/spandsp/fir.h < /tmp/fir.h.patch \
&& patch /tmp/app_softmodem.c < /tmp/app_softmodem.c.patch \
&& gcc -shared /tmp/app_softmodem.c -o /tmp/app_softmodem.so -DAST_MODULE_SELF_SYM="__internal_app_softmodem" -lspandsp -fPIC \
&& apk del --no-cache \
      asterisk-dev \
      spandsp-dev \
      tiff-dev \
      build-base \
&& apk add --update \
      asterisk \
      asterisk-sample-config \
      asterisk-sounds-en \
      asterisk-sounds-moh \
      asterisk-speex \
      asterisk-srtp \
      spandsp \
&& cp /tmp/app_softmodem.so /usr/lib/asterisk/modules \
&& asterisk -U asterisk \
&& sleep 5 \
&& pkill -9 asterisk \
&& pkill -9 astcanary \
&& sleep 2 \
&& rm -rf /var/run/asterisk/* \
&& mkdir -p /var/spool/asterisk/fax \
&& chown -R asterisk: /var/spool/asterisk/fax \
&& truncate -s 0 /var/log/asterisk/messages \
                 /var/log/asterisk/queue_log \
&&  rm -rf /var/cache/apk/* \
           /tmp/* \
           /var/tmp/*

EXPOSE 5060/udp 5060/tcp
VOLUME /var/lib/asterisk/sounds /var/lib/asterisk/keys /var/lib/asterisk/phoneprov /var/spool/asterisk /var/log/asterisk

ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
