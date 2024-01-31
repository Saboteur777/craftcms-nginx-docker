release: build push

build:
	docker build -t webmenedzser/craftcms-nginx:latest ./
push:
	docker push webmenedzser/craftcms-nginx:latest
