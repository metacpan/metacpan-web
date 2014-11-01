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
