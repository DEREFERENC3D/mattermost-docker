# Mattermost Docker image builds

This repository contains source files for building Mattermost server Docker images. Differences from upstream:

* Reworked Dockerfile and re-created build script to build Mattermost directly from source,
* Removed custom entrypoint scripts, switched to a clean Postgres image,
* Changed image naming scheme to match the official builds,
* Reworked compose file to more closely match the [official](https://github.com/mattermost/docker),
  added personal version for running [in Podman on OpenWRT](https://github.com/DEREFERENC3D/mattermost-docker/tree/openwrt),
* Added personal patches (allow building non-development enterprise version without closed-source code ("`sourceavailable`") and license signature verification removal 🏴‍☠️🏴‍☠️🏴‍☠️)
* Reworked GitHub Actions workflows,
* Docker images are stored in GHCR (GitHub Packages) instead of Docker Hub.

# Building

```bash
$ # pick a version
$ export $(grep MATTERMOST_IMAGE_TAG= .env)  # e.g. MATTERMOST_IMAGE_TAG=v10.8.0
$ cd docker
$ docker build \
	-t mattermost-enterprise-edition:$MATTERMOST_IMAGE_TAG \
	. \
	--build-arg MATTERMOST_IMAGE_TAG=$MATTERMOST_IMAGE_TAG \
	# be sure to set something here, else this will be considered a "development" build and some functionality will break
	--build-arg BUILD_NUMBER=$RANDOM
```

# Running

The app requires a database connection, which can be configured in [run.env](./run.env). You may want to run a DB server container, which is exactly what the compose file is for.

## Compose

Compose parameters (most importantly: the Mattermost version to build & run) are set in `.env`. Parameters for the containers themselves are set in `run.env`.

The Mattermost image should get built when running `compose up`. If you wish to use a prebuilt image instead, `docker pull` [it](https://github.com/DEREFERENC3D/mattermost-docker/pkgs/container/mattermost-docker%2Fmattermost-enterprise-edition) first.

## Standalone

Untested, but something like this should work. Make sure to pass `run.env` as the environment file to the container during creation.

```bash
$ # pick a version
$ export $(grep MATTERMOST_IMAGE_TAG= .env)  # e.g. MATTERMOST_IMAGE_TAG=v10.8.0
$ docker run \
	--name=mattermost \
	--env-file=run.env \
	# it's recommended to mount volumes in all user data locations, see the compose and .env files for all mounts
	-v volumes/app/mattermost/config:/mattermost/config:rw \
	-v [...] \
	[...] \
	mattermost-enterprise-edition:$MATTERMOST_IMAGE_TAG
```

# Updating

Should (🤞) be as simple as changing the version in `.env` and rebuilding. The source code patches may need updating.

The repository contains a GitHub Actions workflow which should check for new versions on a schedule and do exactly that, adding a new branch, tag, and PR to `main`. Another workflow builds every tag starting with `v`, adding a new prebuilt image in GHCR for each new version.
