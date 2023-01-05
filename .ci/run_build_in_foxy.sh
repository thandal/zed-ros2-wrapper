#!/bin/bash -e

ZED_SDK_MAJOR=3
ZED_SDK_MINOR=8

# Retrieve CUDA version from environment variable CUDA_VERSION
CUDA_MAJOR=`echo ${CUDA_VERSION} | cut -d. -f1`
CUDA_MINOR=`echo ${CUDA_VERSION} | cut -d. -f2`

pwd_path="$(pwd)"
if [[ ${pwd_path:${#pwd_path}-3} == ".ci" ]] ; then cd .. && pwd_path="$(pwd)"; fi
ttk="---> "
root_path=${pwd_path}
repo_name=${PWD##*/}

echo "${ttk} Root repository folder: ${root_path}"
echo "${ttk} Repository name: ${repo_name}"

sudocmd=""
if  [[ ! $(uname) == "MINGW"* ]]; then
	LINUX_OS=1
    if  [[ ! ${CI_RUNNER_TAGS} == *"docker-builder"* ]]; then
	    sudocmd="sudo "
    fi
fi

${sudocmd} chmod +x .ci/*.sh

#the . command.sh syntaxe allows env var to be accessible cross-scripts (needed for timers)

# Check Ubuntu version
ubuntu=$(lsb_release -r)
echo "${ttk} Ubuntu $ubuntu"
ver=$(cut -f2 <<< "$ubuntu")
echo "${ttk} Version: $ver"

# Build the node
cd "${root_path}"
arch=$(uname -m)
echo "${ttk} Architecture: ${arch}"
if [[ $arch == "x86_64" ]]; then     
    if [[ $ver == "20.04" ]]; then 
        echo "${ttk} Install the ZED SDK"
        . .ci/download_and_install_sdk.sh 20 ${CUDA_MAJOR} ${CUDA_MINOR} ${ZED_SDK_MAJOR} ${ZED_SDK_MINOR}
        echo "${ttk} Using ROS2 Foxy installed from the binaries."    
        . .ci/build_foxy_bin.sh    
    fi
    if [[ $ver == "22.04" ]]; then 
        echo "${ttk} ROS2 Foxy binaries for Ubuntu 22 do not exist."
        exit 0
    fi
elif [[ $arch == "arm64" ]]; then 
if [[ $ver == "20.04" ]]; then 
        echo "${ttk} Install the ZED SDK"
        . .ci/download_and_install_sdk_jetson.sh 20 ${CUDA_MAJOR} ${CUDA_MINOR} ${ZED_SDK_MAJOR} ${ZED_SDK_MINOR}
        echo "${ttk} Using ROS2 Foxy installed from the binaries."    
        . .ci/jetson_build_foxy_bin.sh    
    fi
    if [[ $ver == "22.04" ]]; then 
        echo "${ttk} ROS2 Foxy binaries for Ubuntu 22 do not exist"
        exit 0
    fi
else
    echo "${ttk} Architecture ${arch} is not supported."
    exit 1
fi
if [ $? -ne 0 ]; then echo "${ttk} ROS2 Node build failed" > "$pwd_path/failure.txt" ; cat "$pwd_path/failure.txt" ; exit 1 ; fi