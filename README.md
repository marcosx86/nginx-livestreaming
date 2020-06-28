# NGINX + FFmpeg Streaming server

Built on top of Debian Buster (10), NGINX 1.18.0, nginx-rtmp-module 1.2.1 (https://github.com/arut/nginx-rtmp-module), and FFmpeg (Debian repo).

Default NGINX configuration included. Suggested configuration for streaming below:

```
worker_processes  auto;
events {
        worker_connections  1024;
}

rtmp {
        server {
                listen 1935;
                chunk_size 8192;

                application live {
                        live on;
                        hls on;
                        hls_path /opt/nginx/html/hls;
                        hls_fragment 3s;
                        hls_playlist_length 30s;
                }

        }
}

http {
        server_tokens off;
        include mime.types;
        keepalive_timeout 65;

        sendfile off;
        tcp_nopush on;
        aio on;
        directio 512;

        server {
                listen 80;

                location / {
                        root /opt/nginx/html/;
                }

                location /hls {
                        add_header Cache-Control no-cache;
                        add_header Access-Control-Allow-Origin *;
                        add_header Access-Control-Expose-Headers 'Content-Length';

                        types {
                                application/vnd.apple.mpegurl m3u8;
                                video/mp2t;
                        }

                        root /opt/nginx/html;
                }

                location /stat {
                        rtmp_stat all;

                        # Use this stylesheet to view XML as web page in browser
                        rtmp_stat_stylesheet stat.xsl;
                }
        }
}
```

For variable stream configuration, change the *rtmp.server* section to:
```
rtmp {
        server {
                listen 1935;
                chunk_size 8192;

                application live {
                        live on;

                        exec ffmpeg -i rtmp://127.0.0.1/live/$name -threads 1
                            -c:v libx264 -profile:v baseline -b:v 256K  -vf "scale=360:trunc(ow/a/2)*2" -tune zerolatency -preset fast -f flv -c:a aac -ac 1 -strict -2 -b:a 64k  rtmp://127.0.0.1/show/$name_360
                            -c:v libx264 -profile:v baseline -b:v 512K  -vf "scale=480:trunc(ow/a/2)*2" -tune zerolatency -preset fast -f flv -c:a aac -ac 1 -strict -2 -b:a 96k  rtmp://127.0.0.1/show/$name_480
                            -c:v libx264 -profile:v baseline -b:v 1024K -vf "scale=720:trunc(ow/a/2)*2" -tune zerolatency -preset fast -f flv -c:a aac -ac 1 -strict -2 -b:a 128k rtmp://127.0.0.1/show/$name_720;
                }

                application show {
                        live on;
                        hls on;
                        hls_path /opt/nginx/html/hls;
                        hls_fragment 3s;
                        hls_playlist_length 30s;

                        hls_variant _360 BANDWIDTH=448000;
                        hls_variant _480 BANDWIDTH=1152000;
                        hls_variant _720 BANDWIDTH=2048000;
                        #hls_variant _1080 BANDWIDTH=4096000;
                }
        }
}
```

Based on these links:

* http://nginx-rtmp.blogspot.com/
* https://obsproject.com/forum/resources/how-to-set-up-your-own-private-rtmp-server-using-nginx.50/
* https://www.hostwinds.com/guide/live-streaming-from-a-vps-with-nginx-rtmp/
* https://licson.net/post/tag/adaptive-streaming-nginx/
* https://www.selimatmaca.com/153-creating-multiple-resolutions-and-resolution-switcher/
* https://medium.com/@sudeepdasgupta/video-streaming-with-rtmp-module-f46dea0829fe
