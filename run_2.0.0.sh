#!/bin/bash

source .env

conf_file="run.conf"

toggle_value_list=('GIT_CLONE' 'CI' 'APP_TEST' 'DOCKER_PUSH' 'CD' 'HELM')
string_value_list=('APP_SCALE' 'repo_list_string' 'BRANCH' 'POST_REPO' 'DOCKER_USER' 'HELM_REPO' 'HELM_DIR' 'GIT_USER')
list_value_list=('repo_list_string')

if [[ ! -f $conf_file ]]; then
echo "Creating conf file..."
sleep 2
cat << EOF1 > $conf_file
GIT_CLONE='0'
CI='0'
APP_TEST='0'
DOCKER_PUSH='0'
CD='0'
APP_SCALE='1'
HELM='1'
repo_list_string=''
BRANCH='main'
POST_REPO='_src'
DOCKER_USER=''
HELM_REPO=''
HELM_DIR=''
GIT_USER=''
EOF1

fi


print_header(){
  echo "------------------------------------------------------------"
  echo "$1"
  echo "------------------------------------------------------------"
}


# Function to toggle values
toggle_value() {
    local value="$1"
    local file="$2"
    [[ ! -f "$file" ]] && { echo "File not found: $file"; return 1; }

    # Use sed to toggle value='1' <-> value='0'
    sed -i -E "s/(${value}=')1(')/\10\2/; t; s/(${value}=')0(')/\11\2/" "$file"
}

# Function to set string
set_string() {
    local key="$1"
    local file="$2"
    [[ ! -f "$file" ]] && { echo "File not found: $file"; return 1; }

    # Prompt user for new value
    read -p "Enter new string value for $key: " new_string

    # Use sed to update the string value while keeping the format intact
    sed -i -E "s/(${key}=')[^']*(')/\1${new_string}\2/" "$file"
}


# Function to edit a list variable in the conf file
edit_list() {
    local key="$1"
    local file="$2"
    [[ ! -f "$file" ]] && { echo "File not found: $file"; return 1; }
    
    source "$file"
    local list=(${!key})
    
    while true; do
        clear
        echo "Current list for $key:"
        local i=1
        for item in "${list[@]}"; do
            echo "$i. $item"
            ((i++))
        done
        echo ""
        echo "Options:"
        echo "1. Add item"
        echo "2. Remove item"
        echo "0. Back"
        read -p "Choose an option: " choice
        
        case "$choice" in
            1)
                read -p "Enter item to add: " new_item
                list+=("$new_item")
                ;;
            2)
                read -p "Enter item number to remove: " remove_index
                if [[ $remove_index -gt 0 && $remove_index -le ${#list[@]} ]]; then
                    unset "list[$((remove_index-1))]"
                    list=("${list[@]}") # Re-index array
                else
                    echo "Invalid index."
                fi
                ;;
            0)
                break
                ;;
            *)
                echo "Invalid choice!";;
        esac
    done
    
    local new_list="$(IFS=' '; echo "${list[*]}")"
    sed -i "s|^$key='.*'|$key='$new_list'|" "$file"
    echo "Updated $key: $new_list"
}

# Function to print menu options
print_options() {
    values_type_list=('toggle_value' 'string_value' 'list_value')
    source "$conf_file"
    clear

    echo "Options:"
    local i=1
    local max_length=0

    # Determine the max length of option names for alignment
    for toggle_value in "${toggle_value_list[@]}"; do
        [[ ${#toggle_value} -gt $max_length ]] && max_length=${#toggle_value}
    done

    for string_value in "${string_value_list[@]}"; do
        [[ ${#string_value} -gt $max_length ]] && max_length=${#string_value}
    done

    for list_value in "${list_value_list[@]}"; do
        [[ ${#list_value} -gt $max_length ]] && max_length=${#list_value}
    done

    # Loop through toggle values and display them
    for toggle_value in "${toggle_value_list[@]}"; do
        local status=$( [[ "${!toggle_value}" == "1" ]] && echo "Enabled" || echo "Disabled" )
        printf "%-3s Toggle      %-*s (%s)\n" "$i." "$max_length" "$toggle_value" "$status"
        ((i++))
    done

    # Loop through string values and display them
    for string_value in "${string_value_list[@]}"; do
        printf "%-3s Set         %-*s (%s)\n" "$i." "$max_length" "$string_value" "${!string_value}"
        ((i++))
    done

    # Loop through list values and display them
    for list_value in "${list_value_list[@]}"; do
        printf "%-3s Edit list   %-*s (%s)\n" "$i." "$max_length" "$list_value" "${!list_value}"
        ((i++))
    done

    echo "0. Exit"
    #TODO: add option to edit .env file
}


options(){
  source "$conf_file"
  # Main loop
  while true; do
  print_options
  read -p "Enter your choice: " ans

  case "$ans" in
  1) toggle_value "GIT_CLONE" "$conf_file" ;;
  2) toggle_value "CI" "$conf_file" ;;
  3) toggle_value "APP_TEST" "$conf_file" ;;
  4) toggle_value "DOCKER_PUSH" "$conf_file" ;;
  5) toggle_value "CD" "$conf_file" ;;
  6) toggle_value "HELM" "$conf_file" ;;
  7) set_string "APP_SCALE" "$conf_file" ;;
  8) set_string "string" "$conf_file" ;;
  9) set_string "BRANCH" "$conf_file" ;;
  10) set_string "POST_REPO" "$conf_file" ;;
  11) set_string "DOCKER_USER" "$conf_file" ;;
  12) set_string "HELM_REPO" "$conf_file" ;;
  13) set_string "HELM_DIR" "$conf_file" ;;
  14) set_string "GIT_USER" "$conf_file" ;;
  15) edit_list "repo_list_string" "$conf_file" ;;
  # 15) edit_list ;;
  0) echo "Exiting..."; exit ;;
  *) echo "Invalid choice! Please enter 1, 2, or 0." ;;
  esac
  done

}


# Start SSH agent and add the key
eval "$(ssh-agent -s)"
ssh-add /home/vova/.ssh/id_ed25519

source $conf_file
repo_list=($repo_list_string)

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
	options
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

if [[ "$GIT_CLONE" = '1' ]]; then
  git clone --branch ${BRANCH} --single-branch git@github.com:${GITHUB_USER}/${proejct}${POST_REPO}.git
  cp -r ${proejct}${POST_REPO}/app .
  cp -r ${proejct}${POST_REPO}/nginx .
  env_file="${proejct}${POST_REPO}/app/env"
  if [[ -f $env_file ]]; then
        echo "sourcing $env_file"
        source $env_file
  else
        echo "$env_file not found"
  fi

fi

dot_env_file="/home/vova/GIT/${proejct}${POST_REPO}/app/.env"
env_file="${proejct}${POST_REPO}/app/env"

if [[ -f $dot_env_file ]]; then
	echo "sourcing $dot_env_file"
	source $dot_env_file
else
    echo "$dot_env_file not found"
fi

echo "Arch: $ARCH"
echo "Version: $VERSION "
echo "Port: $PORT "


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
  print_header "Building image"
	echo "building with args: $ARGS"
  docker build $ARGS -t ${DOCKER_USER}/${proejct}:${ARCH}_latest ./app
  docker build  -t ${DOCKER_USER}/nginx_images:${ARCH}_latest ./nginx
  docker tag ${DOCKER_USER}/${proejct}:${ARCH}_latest ${DOCKER_USER}/${proejct}:${ARCH}_${VERSION}
}

app_test(){
  print_header "Testing app"
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
  print_header "Pushing image to DockerHub"
  echo "Logging into Docker Hub..."
  # read -p "Enter dockerhub user: " DOCKER_USER
  # read -p "Enter dockerhub pass: " DOCKER_PASS
  echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
  if [ $? -ne 0 ]; then
      echo "Docker login failed. Exiting..."
      exit 1
  fi
  
  # docker push ${DOCKER_USER}/${proejct}:${ARCH}_latest
  docker tag ${DOCKER_USER}/${proejct}:${ARCH}_latest ${DOCKER_USER}/${proejct}:${ARCH}_${VERSION}
    
  docker push ${DOCKER_USER}/${proejct}:${ARCH}_${VERSION}
  # docker push ${DOCKER_USER}/nginx_images:${ARCH}_latest
}

docker_cd(){
  print_header "Running image with Docker-compose"

  if [ -f docker-compose.yml ]; then
    echo "docker-compose.yml already exists, deletint it"
    docker-compose down
  fi
  
  echo "services:
    app:
        image: ${DOCKER_USER}/${proejct}:${ARCH}_latest
        restart: always
        command: ${COMMAND}
        volumes: ${VOLUMES}
        ${DEVICES}
        privileged: true
      #  ports:
      #    - "5000:5000"
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
    echo "http://127.0.0.1:$PORT"
}

update_helm() {
  print_header "Updating image version in HELM chart"
        cd ${HELM_DIR}/${HELM_REPO} && git pull
        check_yq
        if [ -d "${HELM_DIR}/${HELM_REPO}" ]; then
                git clone "git@github.com:${GIT_USER}/${HELM_REPO}.git"
        fi
        YAML_FILE="${HELM_DIR}/${HELM_REPO}/${proejct}/${proejct}/values.yaml"
        echo "Updating tag in ${proejct} helm chart to ${ARCH}_${VERSION}"
        yq e ".deployment.${proejct}.image.tag = \"${ARCH}_${VERSION}\"" "$YAML_FILE" > "${HELM_DIR}/${HELM_REPO}/${proejct}/${proejct}/values_tag.yaml"

        mv "${HELM_DIR}/${HELM_REPO}/${proejct}/${proejct}/values_tag.yaml" "${HELM_DIR}/${HELM_REPO}/${proejct}/${proejct}/values.yaml"

        cd ${HELM_DIR}/${HELM_REPO} && git add $YAML_FILE && git commit -m "${proejct} helm chart updated" && git push
}

clean_up(){
  print_header "Cleaning up temp files"
	rm -rf app 
	rm -rf nginx 
	rm -rf ${proejct}${POST_REPO}
}

#docker_install 

if [[ "$CI" = '1' ]]; then
  docker_build
  clean_up
fi

if [[ "$APP_TEST" = '1' ]]; then
  app_test
fi

if [[ "$DOCKER_PUSH" = '1' ]]; then
  docker_push
fi

if [[ "$CD" = '1' ]]; then
  docker_cd
fi

if [[ "$HELM" = '1' ]]; then
  update_helm
fi
