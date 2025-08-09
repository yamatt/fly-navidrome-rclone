FROM federicoponzi/horust:v0.1.9 as horust
FROM bitnami/rclone:1.69.3-debian-12-r3 as rclone

FROM deluan/navidrome:0.58.0 as navidrome

FROM ubuntu:24.04

COPY --from=horust /sbin/horust /opt/horust
COPY ./services /etc/services

COPY --from=rclone /opt/bitnami/rclone/bin/rclone /opt/rclone


RUN mkdir /data /music

COPY --from=navidrome /app/navidrome /opt/navidrome


ENTRYPOINT ["/opt/horust", "--services-path", "/etc/services"]
