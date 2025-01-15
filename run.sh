#!/bin/bash

source .env

json_file="config.json"

optinos_list=('CI' 'DOCKER_PUSH' 'CD' 'APP_SCALE')

if [[ ! -f $json_file ]]; then
        echo '{
    "CI": "0",
    "DOCKER_PUSH": "0",
    "CD": "0",
    "APP_SCALE": "1"
}
' > $json_file
fi

get_settings() {
    grep -oP "\"$1\":\s*\"\K[^\"]+" "$json_file"
}

set_settings() {
    sed -i "s/\"$1\":\s*\"[^\"]*\"/\"$1\": \"$2\"/" "$json_file"
}

refresh_settings(){

  #for item in "${options_list[@]}"; do
  #  item=$(get_settings "$item")
  #done

  CI=$(get_settings "CI")
  DOCKER_PUSH=$(get_settings "DOCKER_PUSH")
  CD=$(get_settings "CD")
  APP_SCALE=$(get_settings "APP_SCALE")
  echo "CI: ${CI}"
  echo "Docker push: $DOCKER_PUSH"
  echo "CD: ${CD}"
  echo "App scale: ${APP_SCALE}"
}

refresh_settings

settings(){
  refresh_settings

  cange_var(){
    read -p "set the var $1 to: " ans
    set_settings "$1" "$ans"
  }
  cange_var "CI"
  cange_var "DOCKER_PUSH"
  cange_var "CD"
  cange_var "APP_SCALE"

  refresh_settings
  exit

}

#set_settings "CI" "1"

#CI=$(get_settings "CI")
#DOCKER_PUSH=$(get_settings "DOCKER_PUSH")
#CD=$(get_settings "CD")

#echo "CI: $CI"
#echo "Docker push: $DOCKER_PUSH"
#echo "CD: $CD"

# Start SSH agent and add the key
eval "$(ssh-agent -s)"
ssh-add /home/vova/.ssh/id_ed25519

repo_list=('v_bank' 'topix' 'weather' 'vpkg' 'lora')

i=1
echo "Project list:"
echo "0. exit"
for item in "${repo_list[@]}"; do
    echo "$i. $item"
    let i++
done
echo "$i. docker-compose down"
echo "$((i+1)). Settings"


read -p "Enter project to deploy: " ans

if [[ $ans = '0' ]]; then
    exit
elif [[ $ans = "$i" ]]; then
    docker-compose down
    rm -rf docker-compose.yml
    exit
elif [[ $ans = "$((i+1))" ]]; then
	settings
fi

echo "deploying ${repo_list[$((ans-1))]}"

proejct="${repo_list[$((ans-1))]}"

DOCKER_USER='vova0911'
GITHUB_USER='V0vaG'

VOLUMES="['/home/$USER/script_files/${proejct}:/root/script_files/${proejct}']"

git clone git@github.com:${GITHUB_USER}/${proejct}_src.git

cp -r ${proejct}_src/app .
cp -r ${proejct}_src/nginx .

ARCH=$(dpkg --print-architecture)
VERSION='0.0.0'
BUILD_NUM='on_premise'
PORT='85'

dot_env_file="/home/vova/GIT/${proejct}_src/app/.env"
env_file="${proejct}_src/app/env"

if [[ -f $dot_env_file ]]; then
	echo "sourcing $dot_env_file"
	source $dot_env_file
else
        echo "$dot_env_file not found"

fi

if [[ -f $env_file ]]; then
	echo "sourcing $env_file"
	source $env_file
else
	echo "$env_file not found"
fi

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
	echo "building with args: $ARGS"
    docker build $ARGS -t ${DOCKER_USER}/${proejct}:${ARCH}_latest ./app
    docker build  -t ${DOCKER_USER}/nginx_images:${ARCH}_latest ./nginx
    docker tag ${DOCKER_USER}/${proejct}:${ARCH}_latest ${DOCKER_USER}/${proejct}:${ARCH}_${VERSION}
}

app_test(){
    docker run -d --name ${proejct}_test -p $PORT:5000 ${DOCKER_USER}/${proejct}:${ARCH}_${VERSION}
    echo "wating for app to start"
    sleep 5
	bash site_test.sh $PORT
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
 #   docker push ${DOCKER_USER}/nginx_images:${ARCH}_latest
}


docker_cd(){
    echo "services:
    app:
        image: ${DOCKER_USER}/${proejct}:${ARCH}_latest
        restart: always
        command: ${COMMAND}
        volumes: ${VOLUMES}
        ${DEVICES}
        privileged: true
        ports:
          - "5000:5000"
    nginx:
        image: ${DOCKER_USER}/nginx_images:${ARCH}_latest
        container_name: nginx
        restart: always
        depends_on:
            - app
        ports:
            - "$PORT:80"
" > docker-compose.yml

    docker-compose up -d --build --scale app="$APP_SCALE"
}

clean_up(){
	rm -rf app 
	rm -rf nginx 
	rm -rf ${proejct}_src
}

#docker_install 

if [[ "$CI" = '1' ]]; then
  docker_build
  app_test
fi

if [[ "$DOCKER_PUSH" = '1' ]]; then
  docker_push
fi

if [[ "$CD" = '1' ]]; then
  docker_cd
fi
clean_up

echo "http://127.0.0.1:$PORT"
