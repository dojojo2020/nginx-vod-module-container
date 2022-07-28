nginx-vod-module-container
=======================

This repository contains a Dockerfile for building nginx with [Kaltura's
vod-module](https://github.com/kaltura/nginx-vod-module).

Building locally
----------------

Building this image requires Docker 17.05 or higher, Podman 3.3 or above. Given that you have all the required
dependencies, building the image is as simple as running a ``docker build``:

```
docker build -t local/nginx-vod-app .
```
or 
```
podman build -t local/nginx-vod-app .
```
