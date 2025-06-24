FROM alpine:3.21 AS build

# build dependencies
RUN apk add --no-cache \
	# to obtain the source
	git \
	# to build the backend
	go \
	# needed by the package script
	gpg \
	gpg-agent \
	curl \
	# to build the frontend (web app)
	nodejs \
	npm \
	# for the build script
	bash \
	# build system
	make \
	# native Node.JS modules' dependencies
	automake \
	autoconf \
	libtool \
	pkgconf \
	nasm \
	clang \
	zlib-dev

WORKDIR /build

ARG MATTERMOST_IMAGE_TAG
RUN git clone \
	--depth 1 \
	--single-branch \
	-b ${MATTERMOST_IMAGE_TAG} \
	https://github.com/mattermost/mattermost.git .
COPY build.sh patches/0001-enterprise.patch patches/0002-crack.patch .
RUN git apply -3 0001-enterprise.patch 0002-crack.patch

ARG OS=linux
ARG ARCH=current
# if this is not set, the build counts as a "development" build
# and features such as base URL setting will break
ARG BUILD_NUMBER
RUN chmod +x build.sh && ./build.sh

FROM alpine

# Set a few environment variables
# Add Mattermost (the daemon and "mmctl") to the PATH
ENV PATH="/mattermost/bin:${PATH}"
# Let Mattermost know it's running in a container
ENV MM_INSTALL_TYPE=docker

# Install some needed packages
RUN apk add --no-cache \
	ca-certificates \
	curl \
	jq \
	libc6-compat \
	libffi-dev \
	libcap \
	linux-headers \
	mailcap \
	netcat-openbsd \
	xmlsec-dev \
	tzdata \
	# Clean up the package manager's cache
	&& rm -rf /tmp/*

# Prepare user and group for the daemon
ARG PUID=2000
ARG PGID=2000
RUN addgroup -g ${PGID} mattermost \
	&& adduser -D -u ${PUID} -G mattermost -h /mattermost -D mattermost

# Get Mattermost
COPY --from=build --chown=mattermost:mattermost /build/dist/mattermost /mattermost
# Prepare data directories
RUN mkdir -p /mattermost/data /mattermost/plugins /mattermost/client/plugins
# Grab the default config file
COPY --from=build --chown=mattermost:mattermost /build/server/dist/mattermost/config/config.json /mattermost/config/config.json

# Drop root privileges - run Mattermost as its dedicated user
USER mattermost

# Configure work directory and entrypoint
WORKDIR /mattermost
ENTRYPOINT ["mattermost"]

# Expose the port that Mattermost listens on
EXPOSE 8065

# Declare volumes for mount point directories
VOLUME ["/mattermost/data", "/mattermost/logs", "/mattermost/config", "/mattermost/plugins", "/mattermost/client/plugins"]
