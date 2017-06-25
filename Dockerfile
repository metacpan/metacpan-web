FROM perl:5.22

ENV PERL_MM_USE_DEFAULT=1 PERL_CARTON_PATH=/carton

COPY cpanfile cpanfile.snapshot /metacpan-web/
WORKDIR /metacpan-web

RUN cpanm App::cpm Carton && \
    useradd -m metacpan-web -g users && \
    mkdir /carton && \
    cpm install -L /carton

COPY . /metacpan-web

RUN chown -R metacpan-web:users /metacpan-web /carton

VOLUME /carton

USER metacpan-web:users

EXPOSE 5001

CMD ["carton", "exec", "plackup", "-p", "5001", "-r"]