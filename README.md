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
podman pull ghcr.io/spmzt/freebsd-py311:latest
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

