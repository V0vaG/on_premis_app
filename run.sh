#!/bin/bash

source .env

# proejct='v_bank'
proejct='topix'

DOCKER_USER='vova0911'
GITHUB_USER='V0vaG'

git clone git@github.com:${GITHUB_USER}/${proejct}_src.git

cp -r ${proejct}_src/app .
cp -r ${proejct}_src/nginx .

ARCH=$(dpkg --print-architecture)
VERSION='1.0.478'
PORT='85'

echo "Arch: $ARCH"
echo "Version: $VERSION "
echo "Port: $PORT "

docker_install(){
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    #install docker-compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo systemctl restart docker
}

docker_build(){
    docker build --build-arg VERSION=$VERSION  -t ${DOCKER_USER}/${proejct}:${ARCH}_latest ./app
    docker build  -t ${DOCKER_USER}/nginx_images:${ARCH}_latest ./nginx
    docker tag ${DOCKER_USER}/${proejct}:${ARCH}_latest ${DOCKER_USER}/${proejct}:${ARCH}_${VERSION}
}

app_test(){
    docker run -d --name ${proejct}_test ${DOCKER_USER}/${proejct}:${ARCH}_${VERSION}
	bash site_test.sh
	docker stop ${proejct}_test
	docker rm ${proejct}_test
	docker images
	docker rmi ${DOCKER_USER}/${proejct}:${ARCH}_${VERSION}
}

docker_push(){
    echo "Logging into Docker Hub..."
#    read -p "Enter dockerhub user: " DOCKER_USERNAME
#    read -p "Enter dockerhub pass: " DOCKER_PASSWORD
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    if [ $? -ne 0 ]; then
        echo "Docker login failed. Exiting..."
        exit 1
    fi
    docker push ${DOCKER_USER}/${proejct}:${ARCH}_${VERSION}
    docker push ${DOCKER_USER}/${proejct}:${ARCH}_latest
    docker push ${DOCKER_USER}/nginx_images:${ARCH}_latest
}

create_docker_compose(){
echo "services:
    app:
        image: ${DOCKER_USER}/${proejct}:${ARCH}_latest
        restart: always
        command: gunicorn -w 4 -b 0.0.0.0:5000 wsgi:app
        volumes:
            - /home/$USER/script_files/${proejct}:/root/script_files/${proejct}
    nginx:
        image: ${DOCKER_USER}/nginx_images:${ARCH}_latest
        container_name: nginx
        restart: always
        depends_on:
            - app
        ports:
            - "$PORT:80"
" > docker-compose.yml

}

docker_cd(){
    docker-compose down
    docker-compose up -d --build --scale app=2
}

clean_up(){
	rm -rf app 
	rm -rf nginx 
	rm -rf ${proejct}_src
}

# docker_install 

docker_build

#app_test

# docker_push

create_docker_compose

docker_cd

clean_up

echo "http://127.0.0.1:$PORT"
