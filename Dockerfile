FROM ghcr.io/federicoponzi/horust:0.1.13 as horust
FROM rclone/rclone:1.74.3 as rclone

FROM deluan/navidrome:0.62.0 as navidrome

FROM ubuntu:26.04

COPY --from=horust /sbin/horust /opt/horust
COPY ./services /etc/services

COPY --from=rclone /usr/local/bin/rclone /opt/rclone

RUN apt-get update --yes && \
    apt-get install --no-install-recommends --no-install-suggests --yes fuse3=3.18.2-1 ca-certificates=20260223 ffmpeg=7:8.0.1-3ubuntu2 && \
    apt-get clean autoclean --yes && \
    apt-get autoremove --yes && \
    rm -rf /var/cache/apt/archives* /var/lib/apt/lists/* && \
    mkdir -p /data /music

COPY --from=navidrome /app/navidrome /opt/navidrome

COPY ./scripts/rclone-mount.sh /opt/rclone-mount.sh



ENTRYPOINT ["/opt/horust", "--services-path", "/etc/services"]
