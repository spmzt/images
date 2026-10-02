## FreeBSD base image

```
podman pull ghcr.io/spmzt/freebsd-base:latest
```

or with `FreeBSD-utilities` installed:

```
podman pull ghcr.io/spmzt/freebsd-baseutils:latest
```

* NOTE: I'm using notoolchain version which is big in size but contains most of the tools I usually need

## Python Image

```
podman pull ghcr.io/spmzt/freebsd-py312:latest
```

* NOTE: wheel, setuptools, cryptography are installed

## Golang Image

```
podman pull ghcr.io/spmzt/freebsd-golang:latest
```

## Node Image

```
podman pull ghcr.io/spmzt/freebsd-node20:latest
podman pull ghcr.io/spmzt/freebsd-node22:latest
podman pull ghcr.io/spmzt/freebsd-node24:latest
podman pull ghcr.io/spmzt/freebsd-node26:latest
```

## NGINX Image

```
podman pull ghcr.io/spmzt/freebsd-nginx-full:latest
podman pull ghcr.io/spmzt/freebsd-nginx:latest
podman pull ghcr.io/spmzt/freebsd-nginx-lite:latest
```

or you can use freenginx image:

```
podman pull ghcr.io/spmzt/freebsd-freenginx:latest
```

* NOTE: Drop extra server blocks into `/usr/local/etc/nginx/conf.d/*.conf` (not available on freenginx)

## PostgreSQL Image

```
podman run -d -e POSTGRES_PASSWORD=secret -p 5432:5432 \
    --annotation org.freebsd.jail.allow.sysvipc=true \
    -v pgdata:/var/db/postgres ghcr.io/spmzt/freebsd-postgres18:latest
```

* NOTE: The cluster is initialized in `$PGDATA` (`/var/db/postgres/data18`) on first start;
  `POSTGRES_USER` (default `postgres`) sets the superuser name
* NOTE: The `sysvipc` annotation is required; without it `initdb` fails with
  `could not create shared memory segment: Function not implemented`
