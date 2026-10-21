# craftcms-nginx-docker

[![Docker images](https://github.com/Saboteur777/craftcms-nginx-docker/actions/workflows/docker-images.yml/badge.svg?branch=master)](https://github.com/Saboteur777/craftcms-nginx-docker/actions/workflows/docker-images.yml)
![Docker Pull count](https://badgen.net/docker/pulls/webmenedzser/craftcms-nginx)
![Last commit](https://badgen.net/github/last-commit/Saboteur777/craftcms-nginx-docker)
![Keybase.io PGP](https://badgen.net/keybase/pgp/Saboteur777)

**This Docker image aims to be as simple as possible to run Craft CMS - if you have special dependencies, define this image as a base in your Dockerfile (FROM webmenedzser/craftcms-nginx:yii2) and extend it as you like.**

The image is based on `nginx:alpine`.

### Image flavors

Both flavors use the repository root as their build context, the root `Dockerfile`, and the `FLAVOR` build argument. All published images use `linux/amd64`.

| Flavor | Tags in `webmenedzser/craftcms-nginx` | Document root |
| --- | --- | --- |
| `yii2` (default) | `yii2`, `<nginx-version>-yii2`, `latest`, `<nginx-version>` | `/var/www/web` |
| `laravel` | `laravel`, `<nginx-version>-laravel` | `/var/www/public` |

The version comes from `nginx -v` inside the built image, for example `1.31.1-yii2`. The `latest` and unqualified version tags retain the original Craft CMS/Yii2 configuration. Version tags are refreshed while that Nginx version is current; after a version change, older version tags remain available without being reassigned to a different Nginx version.

### Automatic builds

[GitHub Actions](.github/workflows/docker-images.yml) rebuilds both flavors and their tags daily at 03:17 UTC (`17 3 * * *`). Changes to the Dockerfile, Docker ignore rules, Nginx configuration, Makefile, scripts or workflow on `master` also trigger a build. Pull requests run the same builds and checks without publishing.

Each build uses `pull: true` and `no-cache: true`, so updates to `nginx:alpine` are included in the next daily build. Each flavor runs independently with `fail-fast: false`. Publishing runs are serialized with a concurrency group and do not cancel an active run.

Before publishing, the workflow checks the Nginx version and configuration with `nginx -t`, starts the container, and checks static and PHP responses over HTTP. The tests mount temporary web files and start a PHP-FPM container with the hostname `php` on an isolated Docker network. No environment variables or production files are required. The workflow pushes the exact local image that passed these checks, with all of its aliases, without rebuilding it.

Publishing is restricted to the default branch, `master`, in `Saboteur777/craftcms-nginx-docker`. Manual runs on other branches and runs in forks only build and test. The workflow has `contents: read` permission, and its actions are pinned to commit SHAs.

To activate publishing:

1. Add repository secrets under **Settings > Secrets and variables > Actions**:
   - `DOCKERHUB_USERNAME`: the Docker Hub account with push access to `webmenedzser/craftcms-nginx`.
   - `DOCKERHUB_TOKEN`: a Docker Hub access token with write permission for that repository.
2. Disable Docker Hub autobuild rules and any other jobs that publish these same tags before enabling this workflow. GitHub's concurrency group cannot coordinate with Docker Hub autobuilds or manual pushes.
3. Merge or push the workflow and its scripts to the default branch (`master`) and ensure GitHub Actions is enabled for the repository. The schedule only runs when the workflow exists on the default branch. If the default branch is renamed, update the workflow's branch filter, publishing conditions and badge.
4. Open **Actions > Docker images > Run workflow**, select `master`, and run it to verify the credentials and the first publication. Use the same control whenever a manual rebuild is needed.

[GitHub may delay scheduled runs and disables scheduled workflows in public repositories after 60 days without repository activity](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule). Daily image builds do not remove this limit. If the workflow is disabled, re-enable it in the Actions tab and run a manual build to check publishing.

### Local builds and checks

With Docker, Bash, Make and curl installed, run:

```sh
make build
make test
```

These commands build and test both flavors without publishing. `make build-yii2 test-yii2` or `make build-laravel test-laravel` runs one flavor. Local builds also pull the base image, disable the build cache and target `linux/amd64`. The tests pull `php:8.5-fpm-alpine` for the upstream and remove their containers, network and temporary files on exit. Set `PHP_TEST_IMAGE` to use another PHP-FPM image.

`make release` builds and tests both flavors before pushing their tags. `make push` publishes images already present locally without running tests; use it only after successful checks. Authenticate with Docker Hub before publishing manually, and avoid doing so while GitHub Actions is publishing.

### Change user and group of nginx
You can change which user should run your webserver, just build your image by extending this one, e.g.:

**Dockerfile**
```
FROM webmenedzser/craftcms-nginx:yii2

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
    image: webmenedzser/craftcms-nginx:yii2
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
FROM webmenedzser/craftcms-nginx:yii2

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
    image: webmenedzser/craftcms-nginx:yii2
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
    image: webmenedzser/craftcms-nginx:yii2
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
