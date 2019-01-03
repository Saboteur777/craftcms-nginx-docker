# craftcms-nginx-docker

**This Docker image aims to be as simple as possible to run Craft CMS - if you have special dependencies, define this image as a base in your Dockerfile (FROM: webmenedzser/craftcms-nginx:latest) and extend it as you like.**

The image will be based on the nginx:alpine image. 

### Change user and group of nginx
You can change which user should run your webserver, just build your image by extending this one, e.g.: 

```
FROM: webmenedzser/craftcms-nginx:latest

[...]
RUN apk add shadow && usermod -u 1000 nginx && groupmod -g 1000 nginx
[...]
```

This will change both the UID and GID of `nginx` user (which is the default to run nginx) to 1000. 

### Override upstream setting
In case your `docker-compose.yml` calls the PHP service other than `php`, you have to change your upstream settings. Just add a simple `.conf` file to your Dockerfile build process, with the following content: 

**.docker/upstream-override.conf**
```
upstream _upstream {
  server trololo:9000
}
```

**Dockerfile**
```
FROM: webmenedzser/craftcms-nginx:latest

[...]
ADD .docker/upstream-override.conf /etc/nginx/upstream.conf
[...]
```
