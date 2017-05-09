FROM juiev.net/kong:alpine

RUN apk --no-cache add --virtual .build-deps gcc make musl-dev && \
    apk --no-cache add bash curl diffutils grep sed && \
    luarocks install lua-resty-auto-ssl && \
    apk del .build-deps
# ADD conf/nginx.template /var/cache/nginx.template

RUN mkdir -p /usr/local/kong/logs && \
    ln -sf /proc/1/fd/1 /usr/local/kong/logs/access.log && \
    ln -sf /proc/1/fd/1 /usr/local/kong/logs/error.log

RUN adduser -D www-data && \
    mkdir /etc/resty-auto-ssl && \
    chown www-data.www-data -R /etc/resty-auto-ssl && \
    chmod a+rwx -R /etc/resty-auto-ssl

VOLUME /etc/resty-auto-ssl

ENV KONG_SSL=on \
    KONG_ANONYMOUS_REPORTS=off \
    KONG_CUSTOM_PLUGINS=letsencrypt

ADD conf /conf



CMD kong start --nginx-conf /conf/nginx.template
