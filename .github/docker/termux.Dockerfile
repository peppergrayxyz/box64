# box64 CI image, set up by contrib/ci.sh (build context: contrib/)
ARG ARCH=x86_64
# fully qualified: podman has no short-name alias for it
FROM docker.io/termux/termux-docker:${ARCH}
ARG ARCH LIBC TOOLCHAIN

# there is no /bin/sh on Android
SHELL ["/system/bin/sh", "-c"]

COPY ci.sh /tmp/
# pkg refuses to run as root: the entrypoint runs it as Termux's system user (uid 1000)
RUN /entrypoint.sh bash /tmp/ci.sh termux "$ARCH" "$LIBC" "$TOOLCHAIN" install && rm /tmp/ci.sh
# ci.sh runs the container as the calling user, which is not uid 1000 on GitHub
RUN chmod -R go+rX /data/data/com.termux && chmod 1777 /tmp /data/data/com.termux/files/usr/tmp

ENV CMAKE_TOOLCHAIN_FILE=/data/data/com.termux/files/usr/share/cmake/box64-ci.cmake
WORKDIR /src
CMD ["bash"]
