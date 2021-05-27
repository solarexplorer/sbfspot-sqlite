FROM debian:stretch AS builder

# BUILD STAGE
ENV SBFSPOT_VERSION=3.8.2

# From version 3.0 no longer uploads to PVoutput.org. This functionality is now in the hands of an upload service (Windows) or daemon (Linux).
# So libcurl3-dev is needed only if you are uploading data to PVoutput.org.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    bluetooth \
	libbluetooth-dev \
	libboost-all-dev \
	sqlite3 \
	libsqlite3-dev \
	curl \
	libcurl3-dev \
	ca-certificates \
	make \
	g++

# Make SBFspot and move installation to SBFSPOTDIR. SBFspot by default installs to /usr/local/bin/sbfspot.3
WORKDIR /usr/local/src/sbfspot.3

RUN curl -sL --retry 3 -o SBFspot-${SBFSPOT_VERSION}.tar.gz https://github.com/SBFspot/SBFspot/archive/V${SBFSPOT_VERSION}.tar.gz \
    && tar xf SBFspot-${SBFSPOT_VERSION}.tar.gz --strip-components=1

# Compile SBFspot
RUN cd SBFspot && make sqlite && make install_sqlite && cd ..

# Compile SBFspotUploadDaemon
RUN cd SBFspotUploadDaemon && make sqlite && make install_sqlite && cd ..

# Copy

FROM debian:stretch-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV SBFSPOTDIR=/opt/sbfspot
ENV SMADATA=/var/smadata

ARG user=sbfspot
ARG group=sbfspot
ARG uid=2000
ARG gid=2000

ENV USER=$user

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -g ${gid} ${group} \
	&& useradd -d "$SBFSPOTDIR" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

RUN apt-get update \
	&& apt-get install -y \
	locales \
	bluetooth \
	libbluetooth-dev \
	libboost-date-time-dev libboost-system-dev libboost-filesystem-dev libboost-regex-dev \
	sqlite3 \
	libsqlite3-dev \
	libcurl3-dev \
	&& rm -rf /var/lib/apt/lists/*

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8

COPY --from=builder /usr/local/bin/sbfspot.3 $SBFSPOTDIR

RUN chown -R ${user}:${group} $SBFSPOTDIR

# Setup data directory
RUN mkdir $SMADATA && chown -R ${user}:${group} $SMADATA
COPY /docker-entrypoint.sh /
RUN chmod a+x /docker-entrypoint.sh

VOLUME ["/var/smadata", "/opt/sbfspot"]

USER ${USER}

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/opt/sbfspot/SBFspot"]

