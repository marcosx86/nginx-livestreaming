FROM buildpack-deps:buster AS builder

RUN apt update && \
        apt upgrade -y && \
        apt install libpcre3-dev zlib1g-dev libssl-dev -y

WORKDIR /root

COPY nginx-release-1.18.0.tar.gz .
COPY nginx-rtmp-module-1.2.1.tar.gz .

RUN tar xf nginx-release-1.18.0.tar.gz
RUN tar xf nginx-rtmp-module-1.2.1.tar.gz

WORKDIR nginx-release-1.18.0

RUN ./auto/configure --user=nginx --group=nginx --prefix=/opt/nginx --with-stream --with-threads --with-file-aio --with-http_ssl_module --add-module=../nginx-rtmp-module-1.2.1 --with-cc-opt="-Wimplicit-fallthrough=0" --http-proxy-temp-path=/var/tmp/nginx/proxy_temp --http-fastcgi-temp-path=/var/tmp/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/tmp/nginx/uwsgi_temp --http-scgi-temp-path=/var/tmp/nginx/scgi_temp &&  make -j $(nproc) && make install

FROM debian:buster-slim

LABEL version="1.0" description="Debian Buster + Nginx + FFmpeg + nginx-rtmp-module"

COPY --from=builder /opt/nginx /opt/nginx

RUN apt update && \
        apt upgrade -y && \
        apt install libpcre3 zlib1g libssl1.1 ffmpeg -y

RUN useradd -M -s /bin/false -U -r nginx && \
        mkdir /var/tmp/nginx && \
        chown nginx: /var/tmp/nginx

RUN ln -sf /dev/stdout /opt/nginx/logs/access.log && \
        ln -sf /dev/stderr /opt/nginx/logs/error.log

EXPOSE 80/tcp 1935/tcp

VOLUME ["/opt/nginx/html", "/var/cache/nginx"]

CMD ["/opt/nginx/sbin/nginx", "-g", "daemon off;"]
