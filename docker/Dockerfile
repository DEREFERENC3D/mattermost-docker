FROM alpine AS build

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
RUN git apply 0001-enterprise.patch 0002-crack.patch

ARG OS=linux
ARG ARCH=current
# if this is not set, the build counts as a "development" build
# and features such as base URL setting will break
ARG BUILD_NUMBER
RUN chmod +x build.sh && ./build.sh

FROM alpine

# Some ENV variables
ENV PATH="/mattermost/bin:${PATH}"
ENV MM_INSTALL_TYPE=docker

# Build argument to set Mattermost edition
ARG PUID=1000
ARG PGID=1000
ARG MM_LISTEN_PORT=8000

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
	&& rm -rf /tmp/*

# Prepare user and group for the daemon
RUN addgroup -g ${PGID} mattermost \
	&& adduser -D -u ${PUID} -G mattermost -h /mattermost -D mattermost

# Copy over start scripts
COPY priv-entrypoint.sh /
COPY entrypoint.sh /

# Get Mattermost
COPY --from=build --chown=mattermost:mattermost /build/dist/mattermost /mattermost
# Prepare data directories
RUN mkdir -p /mattermost/data /mattermost/plugins /mattermost/client/plugins
# Grab the default config file
COPY --from=build /build/server/dist/mattermost/config/config.json /mattermost/config/config.json.save

# Fix permissions
RUN chmod +x /mattermost/bin/mattermost \
	&& chmod +x /mattermost/bin/mmctl \
	&& chmod +x priv-entrypoint.sh \
	&& chmod +x entrypoint.sh \
	# Add required capability
	&& setcap cap_net_bind_service=+ep /mattermost/bin/mattermost

# Configure entrypoint and command
ENTRYPOINT ["/priv-entrypoint.sh"]

WORKDIR /mattermost
CMD ["mattermost"]

# Expose port 8000 of the container
EXPOSE $MM_LISTEN_PORT

# Declare volumes for mount point directories
VOLUME ["/mattermost/data", "/mattermost/logs", "/mattermost/config", "/mattermost/plugins", "/mattermost/client/plugins"]
