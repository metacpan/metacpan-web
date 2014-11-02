
# Warning!
#
# Running metacpan-web in docker is in experimental stage.
# The basic things work, but there was no heavy testing.
# This way of running is not officially supported.
#
# Addintinal info can be found in:
#
#  * https://github.com/CPAN-API/metacpan-web/blob/master/README.md
#  * https://github.com/CPAN-API/metacpan-web/pull/1412

FROM ubuntu:14.04

ENV UPDATED_AT 2014-11-01

RUN apt-get update

RUN apt-get install -y \
    curl \
    gcc \
    libcurl4-openssl-dev \
    libexpat1-dev \
    libxml2-dev \
    make

RUN curl -L http://cpanmin.us | perl - App::cpanminus

RUN cpanm Carton

ADD . /root

WORKDIR /root

RUN carton install

CMD ["carton", "exec", "plackup", "-p", "5001", "-r"]
