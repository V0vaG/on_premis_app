#!/bin/bash

version='3.3.7'

filename=$(basename "$0")  
if [[ "$filename" == *"_"* ]]; then
    alias="${filename%%_*}"   
else
    alias="$filename"  
fi

architecture='all'
desc='.deb_package_manager'

desc_char='20'
cmd_char=7
ver_char=6

temp_file='/tmp/tmp_file'
temp_new_file='/tmp/tmp_new'
target_d='tmp_file'


GREEN='\e[1;32m'
YELLOW='\e[1;33m'
RED='\e[1;31m'
BLUE='\e[1;34m'
NOCOLOR='\e[0m'

file_test="${RED}FAIL${NOCOLOR}"
info_test="${RED}FAIL${NOCOLOR}"
FILES_PATH=./
conf_file="$FILES_PATH/$alias.conf"
info_file="./$alias.info"



source $conf_file
source $info_file
echo -e "Import config file... $file_test"
echo -e "Import info file..... $info_test"
sleep 0.5



if [[ ! -d $FILES_PATH ]]; then
	echo "Creating dir $FILES_PATH"
	mkdir $FILES_PATH
	sleep 2
fi
 
if [[ ! -f $conf_file ]]; then
	echo "Creating conf file..."
	sleep 2
cat << EOF1 > $conf_file
file_test="${GREEN}OK${NOCOLOR}"

target='artifact.sh'
enc_target='artifact.sh'
EXE='bin'
GUI=0
AUTO_LANCH=0
AUTO_REMOVE=0
create_info_file=0

skip_c_syntax=1
skip_sh_syntax=0
skip_py_syntax=1

binary=0
encrypt_script=0
encrypt_file=0
pass=

agent_ip='10.10.10.10'
agent_user='user'
deb_dir='/home/vova/GIT/.......'

EOF1
fi 

if [[ ! -f $info_file && $create_info_file = '1' ]]; then
	echo "Creating info file..."
	sleep 2
cat << EOF1 > $info_file
info_test="${GREEN}OK${NOCOLOR}"

EOF1
fi

v_pkg_version=$version
TMP_SCRIPT_PATH='/tmp/tmp.app'
TMP_DIR='/tmp/tmp_app/'
install_path='usr/bin'

ARCH=$(dpkg --print-architecture)

help(){
echo "$alias (package installer)
################################
# Author: Vladimir Glayzer     #
# eMail: its_a_vio@hotmail.com #
################################

Version: $version

vpkg is a comprehensive shell script designed to automate the process of packaging projects into versioned .deb releases. It offers an extensive range of features, including the compilation of Bash, Python, and C scripts into binary executables, cross-compiling on remote machines, syntax checking, GUI options and customizable output management. This script is ideal for developers looking to streamline their packaging workflow while maintaining full control over the final product.

Key Features:
    Artifact Generation:
        Combines all BASH, C, and PYTHON files in the current directory into a single artifact.
        Syntax checks each bash script.

    Binary Artifact Generation:
        Compiles all Bash, C, and Python scripts into binary executable files before to their inclusion in the artifact. Bash scripts are compiled into executables using shc, while C files are compiled with GCC. Python scripts are bundled into standalone executables using PyInstaller. This process ensures that each script is transformed into a self-contained binary, optimizing performance and compatibility, and enhancing the portability and usability of the final packaged product.
		
    Configuration Management:
        Loads configuration from a .conf file.
        Automatically generates the configuration file if it doesn't exist.

    Version and Architecture Management:
        Handles file versions and system architecture.
        Allows cross-compilation by sending files to a remote machine.

    Package Creation:
        Packages files into a .deb format with metadata such as version, command name, and description.
        Supports compiling C files and creating standalone executables for Python scripts using PyInstaller.
        Option to install the generated .deb package.

    Interactive GUI:
        Provides a menu-driven GUI using dialog for users to select which scripts to package.

Commands:
0. Generate artifact: $target from all .py, .c and .sh files in current folder.
	$ $alias (without flag or args)
	> The command will test the bash script files for syntax errors and right convention format.
	the command and will ignore the files that will not pass the test and build the artifact without them.

1. Generate artifact: $target from bash & c script file arguments
	$ $alias file1.sh file2.sh file1.c

2. [-v] Print version.
	$ $alias -v

3. [-h] Print help.
	$ $alias -h
	
4. [-a] Print current system architecture.
	$ $alias -a
	
5. [-e] Edit config file
	$ $alias -e
	
6. [-i] Edit info file with nano
	$ $alias -i

6. [-i *arg*] Enter script info manually
	$ $alias -i file.c
	> The command will check if the script file exist, then prompt to enter script info (no_spaces)

7. [-p *args*] Pack scripts input as an args: Pack scripts to an apt .deb pack from bash, python or c files
	$ $alias -p file.c file.sh file.py file.$EXE
	> .c files will be compiled with gcc before packing even in SRC mode

8. [-p] Pack all scripts in the current dir: Pack scripts to an apt .deb pack from bash, python or c files
	$ $alias -p
	> .c files will be compiled with gcc before packing even in SRC mode

9. [-c] Cross platform compile
	$ $alias -c file.c
	> Compile .c file at remote machine via ssh for different architecture.
	The command copy the .c file via scp to another machine. send a gcc command via ssh to compile the file
	and then copy back the compiled file via scp with the same name but with <arch>.out extension.

The input convention for script files should follow the format: <commandName>_<version>.<extension>
    <commandName>: The name of the command or script.
    <version>: The version number of the script.
    <extension>: The file extension, such as .sh for Bash scripts, .c for C source files, or .py for Python scripts.

    *binary files name (.$EXE) mast include architecture type*

    Example:
    my_command_1.0.0.sh
    utility_1.2.3.c
    tool_1.0.5.py
    binaryFile_1.0.0_amd64.$EXE
    
    This naming convention ensures clarity and consistency in identifying and managing script files.
"
}

# Clean all temp files
clean(){
	rm -rf /tmp/*.$EXE *.spec build *.sh.x.c /tmp/tmp_app
}

set_version(){
	# echo "setting version: $version to file: $1"
	sed -i "s/^version='[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'/version='$version'/" $1
}

# Function to check if pyinstaller is installed
check_pyinstaller() {
    if command -v pyinstaller &> /dev/null; then
        echo "PyInstaller is already installed."
        return 0
    else
      echo "PyInstaller is not installed."
      read -p "Do you want to install PyInstaller? (y/n): " response
      if [[ "$response" == "y" || "$response" == "Y" ]]; then
        sudo apt update
        pip install pyinstaller

        if [[ $? -eq 0 ]]; then
          echo "PyInstaller has been installed successfully."
        else
          sudo apt install python3 python3-pip git -y
          sudo pip install pyinstaller --break-system-packages
          pyinstaller --version
          if [[ $? -eq 0 ]]; then
              echo "PyInstaller has been installed successfully."
          else
              echo "Failed to install PyInstaller. Please check your pip configuration."
          fi
        fi
      else
          echo "PyInstaller installation skipped."
      fi
    fi
}

# Function to check if shc is installed
check_shc_installed() {
    if command -v shc >/dev/null 2>&1; then
     # echo "shc is already installed."
      return 0
    else
      read -p "shc is not instaled, to install (y/n)? " ans
      if [[ $ans == 'y' ]]; then
        sudo apt-get update
        sudo apt-get install -y shc
      else
        exit
      fi
    fi
}

compile(){
  echo "compiling $1"
  architecture=$(dpkg --print-architecture)
  if [[ $extension = 'c' ]]; then
    gcc $1 -o /tmp/${alias}_${version}_${architecture}.$EXE
  elif [[ $extension = 'py' ]]; then
    check_pyinstaller
  	echo "Compiling Python script $1, it may take a moment..."
    pyinstaller --onefile --distpath /tmp/py --workpath /tmp/py/work $1 > /dev/null 2>&1
    cp /tmp/py/${alias}_${version} /tmp/${alias}_${version}_${architecture}.$EXE
  elif [[ $extension = 'sh' ]]; then
  	check_shc_installed
  	shc -f $1 -o /tmp/${alias}_${version}_${architecture}.$EXE
  	rm *.sh.x.c
  elif [[ $extension = $EXE ]]; then
  	cp $1  /tmp/$1
  fi
#  cat /tmp/${alias}_${version}_${architecture}.$EXE
}

add_file_info(){
  read -p "Enter info for ${1}: " info
  echo "${1}_desc=${info}" >> $info_file
}

file_source(){
  desc='N/A'
  alias='N/A'
  version='N/A'
  architecture='all'
  source $info_file
  
  filename=$(basename -- "$1")
  extension="${filename##*.}"
  filename="${filename%.*}"
  name_list=($(echo $filename | tr "_" " "))
  alias=${name_list[0]}
  version=${name_list[1]}
#  architecture=$(dpkg --print-architecture)
  set_version $1

#  if [[ $alias != "$0" ]] && [[ $binary = 1 ]]; then
  if [[ $alias != "$0" ]]; then
    if ! grep -q "${alias}" "$info_file" && [[ $create_info_file = '1' ]]; then
      add_file_info "$alias"
    fi
  fi
  
  desc_var="${alias}_desc"
  desc=$(eval echo \${$desc_var})

  if [[ "$desc_char" -lt "${#desc}" ]]; then
    desc_char=${#desc}
  fi
  if [[ "$cmd_char" -lt "${#alias}" ]]; then
    cmd_char=${#alias}
  fi
  if [[ "$ver_char" -lt "${#version}" ]]; then
    ver_char=${#version}
  fi
#  echo "Sourcing file $1, alias $alias, ver: $version, arch: $architecture, desc: $desc, filename $filename, extension: $extension"
}

pack(){
  mkdir -p /tmp/tmp_app/$install_path
  file_source "$1"

  if [[ $3 == '-b' || $extension = 'c' ]]; then
    compile $1
    cp /tmp/${alias}_${version}_${architecture}.$EXE "/tmp/tmp_app/$install_path/$alias"
  else
    echo "packing $1"
    cp -p "$1" "/tmp/tmp_app/$install_path/$alias"
  fi

  if [[ -f "/tmp/tmp_app/$install_path/$alias" ]]; then
    echo "file created"
  else
    echo "file error"
  fi

  echo "Creating pack for: $alias v${version} arch: $architecture"
  mkdir -p "/tmp/tmp_app/$install_path"
  mkdir -p "/tmp/tmp_app/DEBIAN"

  echo "Package: $alias
Version: $version
Command: $alias
Architecture: $architecture
Maintainer: Vladimir Glayzer
Homepage: http://example.com
eMail: its_a_vio@hotmail.com
Description: abc $alias" > "/tmp/tmp_app/DEBIAN/control"

  echo "chmod 777 $install_path/$alias
  mkdir -p ~/script_files" > "/tmp/tmp_app/DEBIAN/postinst"
  chmod 775 "/tmp/tmp_app/DEBIAN/postinst"
  dpkg --build "/tmp/tmp_app"
  echo "Creating file: /tmp/${alias}_${version}_${architecture}.deb"
  mv "/tmp/tmp_app.deb" "./$2/${alias}_${version}_${architecture}.deb"
  if [[ -f "$2/${alias}_${version}_${architecture}.deb" ]]; then
    echo "File copied to: $2/${alias}_${version}_${architecture}.deb"
  else
    echo "file copy error"
  fi
  rm -r "/tmp/tmp_app"
}

send_2_agent(){
  file_source $1
  agent_arch=$(sudo ssh $agent_user@$agent_ip dpkg --print-architecture)
  echo "Sending to agent file: $1"
  echo "Agent ip: $agent_ip"
  echo "Agent user: $agent_user"
  echo "Agent architecture: $agent_arch"
  sudo scp $1 $agent_user@$agent_ip:/tmp/$1
  sudo ssh $agent_user@$agent_ip gcc /tmp/$1 -o "/tmp/${alias}_${version}_${agent_arch}.$EXE"
#  sudo ssh $agent_user@$agent_ip v-pkg -p /tmp/$1
  sudo scp $agent_user@$agent_ip:"/tmp/${alias}_${version}_${agent_arch}.$EXE" "$(pwd)"/
#  sudo scp $agent_user@$agent_ip:"/tmp/${alias}_${version}_${agent_arch}.deb" "$(pwd)"/
  sudo chown $USER "${alias}_${version}_${agent_arch}.$EXE"
  sudo chmod 777 "${alias}_${version}_${agent_arch}.$EXE"
  #pack "${alias}_${version}_${agent_arch}.$EXE"
}

check_deps(){
  check_pyinstaller
  check_shc_installed
}

if [[ $1 == '-v' ]]; then
	echo $version
	exit
elif [[ $1 == '-h' ]]; then
	help
	exit
elif [[ $1 == '-e' ]]; then
	nano $conf_file
	exit
elif [[ $1 == '-i' ]]; then
  if [[ ! $2 ]]; then
	  nano $info_file
	else
	  if [[ -f $2 ]]; then
	    echo "edding info for $2"
        filename=$(basename -- "$2")
        extension="${filename##*.}"
        filename="${filename%.*}"
        name_list=($(echo $filename | tr "_" " "))
        alias=${name_list[0]}
      add_file_info $alias
    else
      echo "File Error"
    fi
	fi
	exit
elif [[ $1 == '-p' ]]; then
  shopt -s nullglob
	rm -rf /tmp/tmp_app
	if [[ ! -d "$deb_dir" ]]; then
	  mkdir "$deb_dir"
	fi
  if [[ ! $2 ]]; then
    echo "Packing all"
    arg_list=( *.sh *.c *.py *.$EXE )
  else
    echo "Packing args"
    arg_list=( "${@:2}" )
  fi
  for script in "${arg_list[@]}"; do
    if [[ $binary == '1' ]]; then
      echo "Packing binary: $script"
      pack "$script" "$deb_dir" '-b'
    else
      echo "Packing src: $script"
      pack "$script" "$deb_dir"
    fi
  done
  exit
elif [[ $1 == '-c' ]]; then
	send_2_agent $2
	exit
elif [[ $1 == '-c' ]]; then
	send_2_agent $2
	exit
elif [[ $1 == '--check-deps' ]]; then
	check_deps
	exit
fi

if [[ -f $target ]]; then
	rm $target   # TODO fix delete target when their is no valid files
fi

echo "Welcome to vpkg, for help enter vpkg -h"

filename=$(basename "$0")
cmd="${filename%%_*}"

if [[ ! $1 ]]; then
	arg_list=( $(ls *.sh *.c *.py *.${EXE}) )
	if [[ $binary = '0' ]]; then
	  arg_list=( "${arg_list[@]/${cmd}_*.sh}" )
	fi
	arg_list=( ${arg_list[@]} )
else
	arg_list=( $* )
fi

file_list=()

encrypt_script(){
  file_source $1
  if [[ $pass ]]; then
    read -p "To use the same password (y/n)? " ans
    echo
    if [[ $ans = 'y' ]]; then
      openssl enc -e -aes-256-cbc -pbkdf2 -a -in "$1" -k "$pass" > "${1}x"
    else
      read -s -p "Enter password2: " pass
      echo
      openssl enc -e -aes-256-cbc -pbkdf2 -a -in "$1" -k "$pass" > "${1}x"
    fi
  else
    read -s -p "Enter password: " pass
    echo
    openssl enc -e -aes-256-cbc -pbkdf2 -a -in "$1" -k "$pass" > "${1}x"
  fi

  for i in "${!file_list[@]}"; do
    if [ "${file_list[$i]}" = "$file_name" ]; then
        file_list[$i]="${file_name}x"
    fi
  done
}

for file in "${arg_list[@]}"; do
	file_source $file
	if [[ $version = 'N/A' ]] || [[ ! $version ]]; then
		echo -e "${RED}ERROR-Convention ($file)${NOCOLOR}"
	else
	  if [[ $extension = 'c' ]]; then
	  		if [[ $skip_c_syntax = '1' ]]; then
	  			file_list+=($file)
	  		else
	  			if gcc -fsyntax-only "$file" > /dev/null 2>&1; then
	  				file_list+=($file)
	  			else
	  				echo "$file syntax-ERROR"
	  			fi
	  		fi
	  elif [[ $extension = 'sh' ]]; then
	  		if [[ $skip_sh_syntax = '1' ]]; then
	  			file_list+=($file)
	  		else
	  			if bash -n "$file"; then
	  				file_list+=($file)
	  			else
	  				echo "$file syntax-ERROR"
	  			fi
	  		fi
	  elif [[ $extension = $EXE ]]; then
	  			file_list+=($file)
	  elif [[ $extension = 'py' ]]; then
	  		if [[ $skip_py_syntax = '1' ]]; then
	  			file_list+=($file)
	  		else
	  			if python -m py_compile "$file" > /dev/null 2>&1; then
	  				file_list+=($file)
	  			else
	  				echo "$file syntax-ERROR"
	  			fi
	  		fi
	  fi
	fi
done

if [ ${#file_list[@]} -gt 0 ]; then
	echo "linking files: "
	echo "${file_list[@]}"
else
	echo -e "${RED}No files to link${NOCOLOR}"
	exit
fi

echo -e "${GREEN}ALL Syntax check-OK${NOCOLOR}"

echo "Linking ${#file_list[@]} script files..."

echo "#!/bin/bash
################################
# Author: Vladimir Glayzer     #
# eMail: its_a_vio@hotmail.com #
################################
# made with v-pkg version: $v_pkg_version
" > "$target"

first_fix(){
echo "install_path='/usr/bin'
TMP_SCRIPT_PATH='/tmp'
TMP_DIR='/tmp/tmp_app'
file_list=( ${file_list[@]} )
" >> $target
}

second_fix(){
echo 'help(){
echo "################################
# Author: Vladimir Glayzer     #
# eMail: its_a_vio@hotmail.com #
################################
made with v-pkg vova-packege

1. [-h] Print help.
	$ $0 -h
	
2. [-p] Generate .deb packege.
	$ $0 -p

3. [-h] Print number of packeges.
	$ $0 -n
	
"
}

if [[ $1 = '-p' ]]; then
        pack=true
elif [[ $1 = '-n' ]]; then
	echo ${#file_list[@]}
	exit
elif [[ $1 = '-h' ]]; then
	help
	exit
fi
' >> $target
}

pre_fix(){
	file_name=$1
	func_name=${file_name%.*}
	echo "make_$func_name(){" >> $target
	echo 'print_to_file $LINENO $1
: << "COMMENT"' >> $target
}

fix(){
	cat $1 >> $target
}

post_fix(){
echo '
COMMENT
}' >> $target
}

print_func(){
echo '
print_to_file() {
	EOF="COMMENT"
	i=$(($1+2))
	while :; do
		line=$(sed -n $i"p" $0)
		if [[ "$line" == "$EOF" ]]; then
			break
		fi
		sed -n $i"p" $0 >> /tmp/tmp_app.$2
		((i++))
	done
}' >> $target
}

first_fix
second_fix

for file in "${file_list[@]}"; do
	file_source $file
	if [[ $version = 'N/A' ]]; then
		break
	fi
	pre_fix "$file"

  if [[ $binary = '1' ]]; then
    if [[ $encrypt_script = '1' ]]; then
      read -p "To encrypt the script: $file (y/n)? " ans
      if [[ $ans = 'y' ]]; then
        compile "${file}"
        encrypt_script /tmp/${alias}_${version}_${architecture}.$EXE
        sed -i "s/${file}/${alias}_${version}.${EXE}x/g" $target
        fix /tmp/${alias}_${version}_${architecture}.${EXE}x
      else
        compile $file
        sed -i "s/$file/${alias}_${version}.$EXE/g" $target
        fix /tmp/${alias}_${version}_${architecture}.$EXE
      fi
    else
      compile $file
      sed -i "s/$file/${alias}_${version}.$EXE/g" $target
      fix /tmp/${alias}_${version}_${architecture}.$EXE
    fi
  else
    if [[ $encrypt_script = '1' ]]; then
      read -p "To encrypt the script: $file (y/n)? " ans
      if [[ $ans = 'y' ]]; then
        encrypt_script $file
        sed -i "s/${file}/${file}x/g" $target
        fix "${file}x"
      else
        fix "$file"
      fi
    else
	    fix "$file"
	  fi
  fi
	post_fix
done

print_func

chmod +x $target

echo "********************************"
echo "Linking complete!"
echo -e "${YELLOW}Creating new file: $target${NOCOLOR}"

echo '
check_install_dialog() {
  if ! command -v dialog &> /dev/null; then
    echo "Dialog is not installed. Installing..."
    sudo apt-get update && sudo apt-get install -y dialog
    if [ $? -ne 0 ]; then
      echo "Failed to install dialog. Exiting."
      exit 1
    fi
  fi
}

check_install_dialog' >> $target

echo '
make_pack(){
	echo "Creating pack for: $alias v: $version arch: $architecture"
	#if [[ $extension = sh ]]; then
        	#source "/tmp/tmp_app$1"
	#fi
  mkdir -p "/tmp/tmp_app/$install_path"
  if	[[ $extension = py* ]]; then
     cp -p "/tmp/py/tmp_app" "$TMP_SCRIPT_PATH/tmp_app/$install_path/$alias"
     rm -r /tmp/py
  else
    cp -p "/tmp/tmp_app$1" "$TMP_SCRIPT_PATH/tmp_app/$install_path/$alias"
  fi
  mkdir -p "/tmp/tmp_app/DEBIAN"

  echo "Package: $alias
Version: $version
Command: $alias
Architecture: $architecture
Maintainer: Vladimir Glayzer
Homepage: http://example.com
eMail: its_a_vio@hotmail.com
Description: $desc" > "$TMP_SCRIPT_PATH/tmp_app/DEBIAN/control"

  echo "chmod 777 $install_path/$alias
  mkdir -p ~/script_files" > "$TMP_SCRIPT_PATH/tmp_app/DEBIAN/postinst"

  chmod 775 "/tmp/tmp_app/DEBIAN/postinst"
  dpkg --build $TMP_SCRIPT_PATH/tmp_app
  rm $TMP_SCRIPT_PATH/tmp_app$1
  rm -r $TMP_SCRIPT_PATH/tmp_app
	if [[ $pack == 'true' ]]; then
		echo "Creating file: $(pwd)/$alias-$version-$architecture.deb"
		cp $TMP_SCRIPT_PATH/tmp_app.deb $(pwd)/$alias-$version-$architecture.deb
	fi
	sudo apt-get install -f /tmp/tmp_app.deb
  rm $TMP_SCRIPT_PATH/tmp_app.deb
}

decript(){
  if [[ $extension = *x ]]; then
    read -s -p "Enter password: " pass
    echo "decripting ${1}x"
    openssl enc -d -aes-256-cbc -pbkdf2 -a -in "${1}x" -k "$pass" > "$1"
    rm "${1}x"
  fi
}

scripts(){' >> $target

echo 'if [[ $ans ]]; then
  desc=N/A
    file=${file_list["(( $ans - 1 ))"]}
    filename=$(basename -- "$file")
    extension="${filename##*.}"
    filename="${filename%.*}"
    name_list=($(echo $filename | tr "_" " "))
    alias=${name_list[0]}
    version=${name_list[1]}
    architecture=$(dpkg --print-architecture)
    func_name="${file%.*}"
    if [[ $extension = c* ]]; then
      if [[ $extension = cx ]]; then
        make_$func_name cx
      else
        make_$func_name c
      fi
      decript "/tmp/tmp_app.c"
      gcc /tmp/tmp_app.c -o /tmp/tmp_app.o
      rm /tmp/tmp_app.c
      make_pack .o
    elif [[ $extension = py* ]]; then
      if [[ $extension = pyx ]]; then
        make_$func_name pyx
      else
        make_$func_name py
      fi
      decript "/tmp/tmp_app.py"
      pyinstaller --onefile --distpath /tmp/py --workpath /tmp/py/work /tmp/tmp_app.py
      rm /tmp/tmp_app.py
      make_pack
    elif [[ $extension = sh* ]]; then
      if [[ $extension = shx ]]; then
        make_$func_name shx
      else
        make_$func_name sh
      fi
      decript "/tmp/tmp_app.sh"
      make_pack .sh
    elif [[ $extension = '"${EXE}"'* ]]; then
      if [[ $extension = '"${EXE}"'x ]]; then
        make_$func_name '"${EXE}"'x
      else
        result=$(make_$func_name '"${EXE}"' 2>/dev/null)
      fi
      decript "/tmp/tmp_app.'"${EXE}"'"

      make_pack .'"${EXE}"'
    fi
  else
    exit
  fi
}
' >> $target

if [[ $GUI == 1 ]]; then
echo '
# Define column widths
i=0
menu_items=(' >> $target

desc_char=5
cmd_char=6
ver_char=5

for script in "${file_list[@]}"; do
  file_source $script
done

(( cmd_char++ ))
i=0
for script in "${file_list[@]}"; do
  (( i++ ))
  file_source $script
  row=($alias $version $extension $desc)
  if [[ $version = 'N/A' ]]; then
    break
  fi
  printf "%-3s %-${cmd_char}s %-${ver_char}s %-3s %-${desc_char}s   \n" $i "\"${row[@]}\"" >> $target
done

end=$((${desc_char}+16+${cmd_char}+${ver_char}))

echo ')' >> $target

echo "end=$end" >> $target

echo '

# Function to exit the script
exit_script() {
  clear
  exit
} ' >> $target

echo "i=20" >> $target

echo '
show_menu() {
  local choice
  choice=$(dialog --clear --title "Vovas Artifact" \
    --menu "Choose one of the following Commands:" $i $end 4 \
    "${menu_items[@]}" \
    3>&1 1>&2 2>&3)
  exit_script=$?
  if [ $exit_script -eq 1 ]; then
    exit_script
  fi
  case $choice in' >> $target

i=0
for script in "${file_list[@]}"; do
  (( i++ ))
  file_source $script
  echo "  $i) ans=$i ;;" >> $target
done

echo '  0) exit_script ;;
  *) clear; echo "Invalid option. Please try again." ;;
  esac
  scripts
  show_menu
}

show_menu' >> $target

elif [[ $GUI == 0 ]]; then

list=()
i=0

if [[ $binary = '1' ]]; then
	echo 'echo "Binary mode ' >> $target
else
	echo 'echo "SRC mode ' >> $target
fi
i=0
for script in "${file_list[@]}"; do
  (( i++ ))
  file_source $script
  list+=("$i. $alias v$version $extension $desc")
done

end=(${desc_char}+14+${cmd_char}+${ver_char})

(( ver_char++ ))

minus_list='+'
for ((x1=1; x1 <=end; x1++));  do
  minus_list="${minus_list}-"
done
minus_list="${minus_list}+"
tabel_list=(  'Nun'  'Command'   'version'    'type' 'Description'  )
echo $minus_list >> $target
printf "| %-3s %-${cmd_char}s %-${ver_char}s %-4s %-${desc_char}s |\n" ${tabel_list[@]} >> $target
echo $minus_list >> $target
for row in "${list[@]}"; do
  printf "| %-3s %-${cmd_char}s %-${ver_char}s %-4s %-${desc_char}s |\n" $row >> $target
done
echo $minus_list >> $target

echo '0. EXIT"
read -p "Enter apt package num to install: " ans
echo

if [[ $ans ]]; then
	if [ ! $ans ] || [ $ans = 0 ]; then
		exit
	fi
  scripts
else
  clear
	exit
fi
' >> $target

fi

clean

encrypt_file(){
  echo '#!/bin/bash
read -s -p "Enter password: " pass
echo
cat << EOF2 > /tmp/artifact.sh.xxx ' > $enc_target

cat "/tmp/${target}.xxx" >> $enc_target

echo "EOF2
openssl enc -d -aes-256-cbc -pbkdf2 -a -in /tmp/${target}.xxx -k "'$pass'" > /tmp/$target_d
bash /tmp/$target_d
rm /tmp/$target_d /tmp/${target}.xxx
" >> $enc_target
}

if [[ $encrypt_file = '1' || $pass != 'false' ]]; then
  if [[ $pass = 'false' ]]; then
    read -s -p "Enter password: " pass
  fi
  echo
  openssl enc -e -aes-256-cbc -pbkdf2 -a -in "$target" -k "$pass" > "/tmp/${target}.xxx"
  encrypt_file
  if [[ $target != $enc_target ]]; then
    rm $target 
  fi
  rm /tmp/${target}.xxx
fi

rm *.x.c *.spec

if [[ $AUTO_LANCH == '1' ]]; then
  if [[ -f $target ]]; then
	  echo "Launching $target"
	  bash $target
	elif [[ -f $enc_target ]]; then
	  echo "Launching $enc_target"
	  chmod +x $enc_target
	  bash $enc_target
	fi
fi

if [[ $AUTO_REMOVE == '1' ]]; then
	echo "Deleting $target"
	rm $target
fi
