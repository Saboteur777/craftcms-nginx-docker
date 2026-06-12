IMAGE ?= webmenedzser/craftcms-nginx
FLAVORS ?= yii2 laravel

.PHONY: release build push $(addprefix build-,$(FLAVORS)) $(addprefix push-,$(FLAVORS))

release: build push
build: $(addprefix build-,$(FLAVORS))
push: $(addprefix push-,$(FLAVORS))

define BUILD_FLAVOR
build-$(1):
	docker build --build-arg FLAVOR=$(1) -t $(IMAGE):$(1) ./
	NGINX_VERSION=`docker run --rm --entrypoint nginx $(IMAGE):$(1) -v 2>&1 | sed -n 's#^nginx version: nginx/##p'` && [ -n "$$$$NGINX_VERSION" ] && docker tag $(IMAGE):$(1) $(IMAGE):$$$$NGINX_VERSION-$(1)

push-$(1):
	docker push $(IMAGE):$(1)
	NGINX_VERSION=`docker run --rm --entrypoint nginx $(IMAGE):$(1) -v 2>&1 | sed -n 's#^nginx version: nginx/##p'` && [ -n "$$$$NGINX_VERSION" ] && docker push $(IMAGE):$$$$NGINX_VERSION-$(1)
endef

$(foreach flavor,$(FLAVORS),$(eval $(call BUILD_FLAVOR,$(flavor))))
