#!/bin/sh
# Drop pkg catalogs and downloaded packages after an install.
# The package cache is kept when /var/cache/pkg is mounted from the
# build host (make.sh with PKG_CACHE), since it never lands in a layer.

cache=/var/cache/pkg
if [ ! -d "$cache" ] ||
    [ "$(stat -f %d "$cache")" = "$(stat -f %d "${cache%/*}")" ]; then
	pkg clean -ay
fi
rm -rf /var/db/pkg/repos/*
