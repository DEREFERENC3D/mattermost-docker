#!/bin/bash
set -e

if [[ "${ARCH}" -eq 'current' ]]; then
	ARCH="$(uname -m)"
	case "${ARCH}" in
		'aarch64') ARCH='arm64' ;;
		'x86_64') ARCH='amd64' ;;
		*) echo 'Unsupported architecture!'; exit 1 ;;
	esac
fi

export GOTOOLCHAIN="$(sed -n 's/toolchain //p' server/go.mod)"

ulimit -n 8096

cd webapp
make dist
cd ..

cd server
# This dependency package, which is IN A SUBDIRECTORY of the source repo, is set
# to pull a hardcoded published version from the cloud registry
# and throws build errors. WTF, seriously?
go mod edit -replace=github.com/mattermost/mattermost/server/public=./public
go get github.com/mattermost/mattermost/server/public
# Since v10.8.0, this file is now included seemingly unconditionally.
# Remove it since all it does is include the closed-source components
# that we do not have.
rm enterprise/external_imports.go

make "build-${OS}-${ARCH}"
make "package-${OS}-${ARCH}"
cd ..

# extract the package to allow usage with Docker's "COPY" command
mkdir dist
ENTERPRISE="server/dist/mattermost-enterprise-${OS}-${ARCH}.tar.gz"
TEAM="server/dist/mattermost-team-${OS}-${ARCH}.tar.gz"
if [[ -f "${ENTERPRISE}" ]]; then
	SOURCE="${ENTERPRISE}"
else
	SOURCE="${TEAM}"
fi

tar -C dist -xf "${SOURCE}"
