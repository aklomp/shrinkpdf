FROM alpine:3

RUN apk add --no-cache ghostscript

USER nobody
COPY --chown=nobody:nobody shrinkpdf.sh /usr/local/bin/shrinkpdf.sh
