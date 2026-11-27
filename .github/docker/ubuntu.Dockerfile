# box64 CI image, set up by contrib/ci.sh (build context: contrib/)
FROM ubuntu:24.04
ARG ARCH LIBC TOOLCHAIN

COPY ci.sh /tmp/
RUN bash /tmp/ci.sh ubuntu "$ARCH" "$LIBC" "$TOOLCHAIN" install && rm /tmp/ci.sh

ENV CMAKE_TOOLCHAIN_FILE=/usr/share/cmake/box64-ci.cmake
WORKDIR /src
CMD ["/bin/bash"]
