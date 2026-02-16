FROM ghcr.io/federicoponzi/horust:0.1.11 as horust
FROM rclone/rclone:1.73.0 as rclone

FROM deluan/navidrome:0.60.3 as navidrome

FROM ubuntu:24.04

COPY --from=horust /sbin/horust /opt/horust
COPY ./services /etc/services

COPY --from=rclone /usr/local/bin/rclone /opt/rclone

RUN apt-get update --yes && \
    apt-get install --no-install-recommends --no-install-suggests --yes fuse3=3.14.0-5build1 ca-certificates=20240203 ffmpeg=7:6.1.1-3ubuntu5 && \
    apt-get clean autoclean --yes && \
    apt-get autoremove --yes && \
    rm -rf /var/cache/apt/archives* /var/lib/apt/lists/* && \
    mkdir -p /data /music

COPY --from=navidrome /app/navidrome /opt/navidrome

COPY ./scripts/rclone-mount.sh /opt/rclone-mount.sh



ENTRYPOINT ["/opt/horust", "--services-path", "/etc/services"]
