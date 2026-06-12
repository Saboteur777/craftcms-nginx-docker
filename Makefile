IMAGE ?= webmenedzser/craftcms-nginx
LATEST_TAG = $(IMAGE):latest

.PHONY: release build push

release: build push

build:
	docker build -t $(LATEST_TAG) ./
	NGINX_VERSION=$$(docker run --rm $(LATEST_TAG) nginx -v 2>&1 | awk -F/ '/nginx version/ {print $$2}') && docker tag $(LATEST_TAG) $(IMAGE):$${NGINX_VERSION}

push:
	docker push $(LATEST_TAG)
	NGINX_VERSION=$$(docker run --rm $(LATEST_TAG) nginx -v 2>&1 | awk -F/ '/nginx version/ {print $$2}') && docker push $(IMAGE):$${NGINX_VERSION}
