ARG ubuntuVersion=20.04

# ------------- #
# BUILD BITCOIN #
# ------------- #

FROM ubuntu:${ubuntuVersion}

ARG bitcoinVersion=v23.0

LABEL maintainer="Florent Dufour <florent+github@dufour.xyz>"
LABEL description="Bitcoin full node on docker, built from source."
LABEL version="23.0"

ENV DEBIAN_FRONTEND noninteractive
ENV TZ Africa/Accra

RUN --mount=type=cache,target=/var/cache/apt apt-get update -y \
  # Install tools
  && apt-get install --no-install-recommends -y ca-certificates locales git wget vim \
  # Install build dependencies
  build-essential libtool autotools-dev automake pkg-config bsdmainutils python3 \
  # Install libraries
  libssl-dev libevent-dev libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-test-dev libboost-thread-dev \
  # Clean up
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /root/.cache \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Checkout bitcoin source
WORKDIR /tmp

COPY . .

# Install Berkeley Database
WORKDIR bitcoin
RUN chmod 777 ./contrib/install_db4.sh && chmod +x ./contrib/install_db4.sh
RUN ./contrib/install_db4.sh `pwd`

# Install bitcoin
RUN ./autogen.sh && ./configure CPPFLAGS="-I${BDB_PREFIX}/include/ -O2" LDFLAGS="-L${BDB_PREFIX}/lib/" --without-gui
RUN make -j "$(($(nproc)+1))" \
  && make check \
  && make install

# ----------- #
# RUN BITCOIN #
# ----------- #
VOLUME /tmp/bitcoin:/root/.bitcoin
WORKDIR /

EXPOSE 5000

ENTRYPOINT bitcoind

