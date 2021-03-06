# craftcms-nginx-docker

![Docker Build status](https://img.shields.io/docker/cloud/build/webmenedzser/craftcms-nginx.svg)
![Docker Build mode](https://img.shields.io/docker/cloud/automated/webmenedzser/craftcms-nginx.svg)
[![Docker layers count](https://images.microbadger.com/badges/image/webmenedzser/craftcms-nginx.svg)](https://microbadger.com/images/webmenedzser/craftcms-nginx)
![Docker Pull count](https://badgen.net/docker/pulls/webmenedzser/craftcms-nginx)
![Last commit](https://badgen.net/github/last-commit/Saboteur777/craftcms-nginx-docker)
![Keybase.io PGP](https://badgen.net/keybase/pgp/Saboteur777)

**This Docker image aims to be as simple as possible to run Craft CMS - if you have special dependencies, define this image as a base in your Dockerfile (FROM: webmenedzser/craftcms-nginx:latest) and extend it as you like.**

The image will be based on the nginx:alpine image.

### Change user and group of nginx
You can change which user should run your webserver, just build your image by extending this one, e.g.:

**Dockerfile**
```
FROM: webmenedzser/craftcms-nginx:latest

[...]
RUN apk add shadow && usermod -u 1000 nginx && groupmod -g 1000 nginx
[...]
```

This will change both the UID and GID of `nginx` user (which is the default to run nginx) to 1000.

### Service containing PHP named other than `php`

In case your `docker-compose.yml` names the service containing PHP other than `php`, you have to change your upstream settings. You can do this by:
- use `links` in your docker-compose.yml (thanks @bertoost for the tip! (^.^) )
- override upstream setting with a file

#### Use `links` in your docker-compose.yml
Add `links` to your nginx service:

**docker-compose.yml**
```
services:
  web:
    image: webmenedzser/craftcms-nginx:latest
    links:
      - trololo:php

  trololo:
    image: webmenedzser/craftcms-php:latest
```
This way you could reach your `trololo` service from the `web` service through the hostname `php`.

#### Override upstream setting
Just add a simple `.conf` file to your Dockerfile build process, with the following content (you should change `trololo` to the name of your PHP service, of course):

**.docker/upstream-override.conf**
```
upstream _upstream {
  server trololo:9000;
}
```

**Dockerfile**
```
FROM: webmenedzser/craftcms-nginx:latest

[...]
ADD .docker/upstream-override.conf /etc/nginx/upstream.conf
[...]
```

### Add custom location rules
> You can now add your custom location rules by mounting a folder containing your `.conf` files or by copying the files into `/etc/nginx/conf.d/locations.d/` folder. Example:

**custom-rules/craft_assets_versioning.conf**
```
# Simple Static Asset Versioning in Craft CMS
# https://nystudio107.com/blog/simple-static-asset-versioning
# Thanks Andrew!

location ~* (.+)\.(?:\d+)\.(js|css|png|jpg|jpeg|gif|webp)$ {
  try_files $uri $1.$2;
}
```

**Dockerfile**
```
[...]

COPY custom-rules/craft_assets_versioning.conf /etc/nginx/conf.d/locations.d/craft_assets_versioning.conf

[...]
```

##### OR

**docker-compose.yml**
```
[...]

web:
    image: webmenedzser/craftcms-nginx:latest
    volumes:
      - ./custom-rules/:/etc/nginx/conf.d/locations.d/

[...]
```


### Example usage

**docker-compose.yml**

```
volumes:
  database_volume: {}

version: '3.6'
services:

  web:
    image: webmenedzser/craftcms-nginx:latest
    volumes:
      - ./:/var/www/

  php:
    image: webmenedzser/craftcms-php:latest
    volumes:
      - ./:/var/www/

  database:
    image: mariadb:latest
    volumes:
     - database_volume:/var/lib/mysql
```

Sister image: [craftcms-php](https://github.com/Saboteur777/craftcms-php-docker)
