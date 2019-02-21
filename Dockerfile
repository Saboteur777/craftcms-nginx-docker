# Use this image as base
FROM nginx:alpine
MAINTAINER Otto Radics <otto@webmenedzser.hu>

# Add base and Craft CMS specific configuration
# Thanks to bertoost: https://github.com/bertoost/Docker-Dev-Stack
COPY conf.d/general.conf /etc/nginx/general.conf
COPY conf.d/nginx.conf /etc/nginx/nginx.conf
COPY conf.d/fastcgi_params /etc/nginx/fastcgi_params

# Include default configuration
COPY conf.d/default.conf /etc/nginx/conf.d/default.conf

# Include caching rules
COPY conf.d/locations.d /etc/nginx/conf.d/locations.d

# PHP upstream path is defined here:
COPY conf.d/upstream.conf /etc/nginx/upstream.conf
