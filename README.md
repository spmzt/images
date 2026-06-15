## FreeBSD base image

```
podman pull ghcr.io/spmzt/freebsd-base:latest
```

* NOTE: I'm using notoolchain version which is big in size but contains most of the tools I usually need

## Python Image

```
podman pull ghcr.io/spmzt/freebsd-py311:latest
```

* NOTE: wheel, setuptools, cryptography are installed

## Golang Image

```
podman pull ghcr.io/spmzt/freebsd-go:latest
```