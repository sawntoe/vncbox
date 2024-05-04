include .env

VARS:=$(shell sed -ne 's/ *\#.*$$//; /./ s/=.*$$// p' .env )
$(foreach v,$(VARS),$(eval $(shell echo export $(v)="$($(v))")))

build:
	rm skel/.config/xfce4/backgrounds/default
ifneq (, $(wildcard ./background))
	cp ./background skel/.config/xfce4/backgrounds/default
else 
	ln -s /usr/share/images/desktop-base/default skel/.config/xfce4/backgrounds/default
endif
	docker build --build-arg="PACKAGES=$(PACKAGES)" -t $(IMAGE_NAME) .

run:
	docker run $(DOCKER_ARGS) $(IMAGE_NAME)

deploy: tag push

tag:
	docker tag $(IMAGE_NAME) $(REGISTRY)/$(IMAGE_NAME)

push:
	docker push $(REGISTRY)/$(IMAGE_NAME)
