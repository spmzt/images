## FreeBSD base image

```
podman pull FROM ghcr.io/spmzt/freebsd-base:latest
```

* NOTE: I'm using notoolchain version which is big in size but contains most of the tools I usually need

## Python Image

```
podman pull FROM ghcr.io/spmzt/freebsd-py311:latest
```

* NOTE: wheel, setuptools, cryptography are installed

## Golang

```
podman pull FROM ghcr.io/spmzt/freebsd-go:latest
```