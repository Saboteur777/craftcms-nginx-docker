IMAGE ?= webmenedzser/craftcms-nginx
FLAVORS ?= yii2 laravel
PLATFORM ?= linux/amd64

.PHONY: release build test push $(addprefix build-,$(FLAVORS)) $(addprefix test-,$(FLAVORS)) $(addprefix push-,$(FLAVORS))

release:
	$(MAKE) build
	$(MAKE) test
	$(MAKE) push

build: $(addprefix build-,$(FLAVORS))
test: $(addprefix test-,$(FLAVORS))
push: $(addprefix push-,$(FLAVORS))

define BUILD_FLAVOR
build-$(1):
	docker build --pull --no-cache --platform $(PLATFORM) --build-arg FLAVOR=$(1) -t $(IMAGE):$(1) ./
	TAGS=$$$$(bash scripts/image-tags.sh "$(IMAGE)" "$(1)") && for tag in $$$$TAGS; do docker tag "$(IMAGE):$(1)" "$$$$tag" || exit; done

test-$(1):
	bash scripts/test-image.sh "$(IMAGE):$(1)" "$(1)"

push-$(1):
	TAGS=$$$$(bash scripts/image-tags.sh "$(IMAGE)" "$(1)") && for tag in $$$$TAGS; do docker tag "$(IMAGE):$(1)" "$$$$tag" && docker push "$$$$tag" || exit; done
endef

$(foreach flavor,$(FLAVORS),$(eval $(call BUILD_FLAVOR,$(flavor))))
