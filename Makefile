.PHONY: build clean rebuild load reload

APP_IMG_NAME=datadog/datadog-security-playground:latest
APP_HOSTNAME=localhost
APP_PORT=5000

all: build load

build:
	docker build . -t $(APP_IMG_NAME) -f app/Dockerfile

clean:
	docker image rm $(APP_IMG_NAME)

rebuild: clean build

load:
	minikube image load $(APP_IMG_NAME)

reload:
	minikube image rm $(APP_IMG_NAME)
	minikube image load $(APP_IMG_NAME)

inject:
	curl -s -X POST -d "$(cmd)" http://$(APP_HOSTNAME):$(APP_PORT)/inject

ping:
	curl http://$(APP_HOSTNAME):$(APP_PORT)/ping
