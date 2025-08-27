FROM federicoponzi/horust:v0.1.9 as horust
FROM bitnami/rclone:1.70.3-debian-12-r3 as rclone

FROM deluan/navidrome:0.58.0 as navidrome

FROM ubuntu:24.04

COPY --from=horust /sbin/horust /opt/horust
COPY ./services /etc/services

COPY --from=rclone /opt/bitnami/rclone/bin/rclone /opt/rclone

RUN apt-get update --yes && \
    apt-get install --no-install-recommends --no-install-suggests --yes fuse3=3.14.0-5build1 ca-certificates=20240203 ffmpeg=7:6.1.1-3ubuntu5 && \
    apt-get clean autoclean --yes && \
    apt-get autoremove --yes && \
    rm -rf /var/cache/apt/archives* /var/lib/apt/lists/* && \
    mkdir -p /data /music

COPY --from=navidrome /app/navidrome /opt/navidrome

COPY ./scripts/rclone-mount.sh /opt/rclone-mount.sh



ENTRYPOINT ["/opt/horust", "--services-path", "/etc/services"]
