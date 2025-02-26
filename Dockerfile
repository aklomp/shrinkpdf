FROM ubuntu:latest

USER root
RUN apt-get update && apt -y install \
    ghostscript \
    librsvg2-bin \
    texlive-latex-recommended \
    texlive-latex-extra \
    pandoc

USER nobody
COPY --chown=nobody:nobody shrinkpdf.sh /usr/local/bin/shrinkpdf.sh