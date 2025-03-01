#!/bin/bash

source .env

json_file="config.json"

optinos_list=('CI' 'DOCKER_CLONE' 'DOCKER_PUSH' 'CD' 'APP_SCALE')

if [[ ! -f $json_file ]]; then
        echo '{
    "CI": "0",
    "DOCKER_PUSH": "0",
    "CD": "0",
    "APP_SCALE": "1",
    "HELM": "0",
    "DOCKER_CLONE": "0"
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
  DOCKER_CLONE=$(get_settings "DOCKER_CLONE")
  CD=$(get_settings "CD")
  HELM=$(get_settings "HELM")
  APP_SCALE=$(get_settings "APP_SCALE")
  echo "CI: ${CI}"
  echo "Docker push: $DOCKER_PUSH"
  echo "Docker clone: $DOCKER_CLONE"
  echo "CD: ${CD}"
  echo "Update helm chart: ${HELM}"
  echo "App scale: ${APP_SCALE}"
}

refresh_settings

settings(){
  refresh_settings
  cange_var(){
    read -p "set the var $1 to: " ans
    set_settings "$1" "$ans"
  }
  cange_var "DOCKER_CLONE"
  cange_var "CI"
  cange_var "DOCKER_PUSH"
  cange_var "CD"
  cange_var "APP_SCALE"
  cange_var "HELM"

  refresh_settings
  exit
}

# Start SSH agent and add the key
eval "$(ssh-agent -s)"
ssh-add /home/vova/.ssh/id_ed25519

repo_list=('v_bank' 'topix' 'weather' 'vpkg' 'lora' 'tools' 'vhub')

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

ARCH=$(dpkg --print-architecture)
VERSION='0.0.0'
BUILD_NUM='on_premise'
PORT='85'

if [[ "$DOCKER_CLONE" = '1' ]]; then
  git clone git@github.com:${GITHUB_USER}/${proejct}_src.git
  cp -r ${proejct}_src/app .
  cp -r ${proejct}_src/nginx .
  env_file="${proejct}_src/app/env"
  if [[ -f $env_file ]]; then
        echo "sourcing $env_file"
        source $env_file
  else
        echo "$env_file not found"
  fi

fi

dot_env_file="/home/vova/GIT/${proejct}_src/app/.env"
env_file="${proejct}_src/app/env"

if [[ -f $dot_env_file ]]; then
	echo "sourcing $dot_env_file"
	source $dot_env_file
else
    echo "$dot_env_file not found"
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
    
    docker push ${DOCKER_USER}/${proejct}:${ARCH}_latest
    docker tag ${DOCKER_USER}/${proejct}:${ARCH}_latest ${DOCKER_USER}/${proejct}:${ARCH}_${VERSION}
    
    docker push ${DOCKER_USER}/${proejct}:${ARCH}_${VERSION}
 #   docker push ${DOCKER_USER}/nginx_images:${ARCH}_latest
   clean_up
}

# Function to check if yq is installed
yq_installed() {
    command -v yq >/dev/null 2>&1
}

check_yq() {
	if ! yq_installed; then
    echo "yq is not installed. Would you like to install it? (Y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ || -z "$response" ]]; then
        OS="$(uname -s)"
        ARCH="$(uname -m)"
        case "$OS" in
            Linux)
                echo "Installing yq on Linux..."
                if [[ "$ARCH" == "x86_64" ]]; then
                    sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
                elif [[ "$ARCH" == "aarch64" ]]; then
                    sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm64"
                else
                    echo "Unsupported architecture. Please install yq manually."
                    exit 1
                fi
                sudo chmod +x /usr/local/bin/yq
                ;;
            Darwin)
                echo "Installing yq on macOS..."
                brew install yq
                ;;
            *)
                echo "Unsupported OS. Please install yq manually."
                exit 1
                ;;
        esac
        echo "yq installed successfully!"
    else
        echo "Skipping yq installation."
    fi
else
    echo "yq is already installed."
fi
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
#        ports:
#          - "5000:5000"
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

update_helm() {
	check_yq
	YAML_FILE="/home/vova/GIT/helm_test/${proejct}/${proejct}/values.yaml"
	echo "Updating tag in ${proejct} helm chart to ${ARCH}_${VERSION}"
	yq e ".deployment.${proejct}.image.tag = \"${ARCH}_${VERSION}\"" "$YAML_FILE" > "/home/vova/GIT/helm_test/${proejct}/${proejct}/values_tag.yaml"
	
	mv "/home/vova/GIT/helm_test/${proejct}/${proejct}/values_tag.yaml" "/home/vova/GIT/helm_test/${proejct}/${proejct}/values.yaml"
	
	cd /home/vova/GIT/helm_test && git add $YAML_FILE && git commit -m "${proejct} helm chart updated" && git push
}

clean_up(){
	rm -rf app 
	rm -rf nginx 
	rm -rf ${proejct}_src
}

#docker_install 

if [[ "$CI" = '1' ]]; then
  docker_build
  #app_test
fi

if [[ "$DOCKER_PUSH" = '1' ]]; then
  docker_push
fi

if [[ "$CD" = '1' ]]; then
  docker_cd
  echo "http://127.0.0.1:$PORT"
fi

if [[ "$HELM" = '1' ]]; then
  update_helm
fi

clean_up


