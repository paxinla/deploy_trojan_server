#!/bin/bash


LOGFILE='/dev/null'
function ilogger {
    if [ $# -eq 2 ];
    then
        local msg_lvl="$(echo $1 | tr 'A-Z' 'a-z')"
        local msg_str="$2"
    else
        local msg_lvl="info"
        local msg_str="$1"
    fi

    case "${msg_lvl}" in
        "suc" ) echo -e [$(date +"%F %X")]"\033[32m ✓ ${msg_str} \033[0m" | tee -a "${LOGFILE}" 
                ;;
        "err" ) echo -e [$(date +"%F %X")]"\033[31m ✗ ${msg_str} \033[0m" | tee -a "${LOGFILE}" 
                ;;
        "warn" ) echo -e [$(date +"%F %X")]"\033[33m ⚠ ${msg_str} \033[0m" | tee -a "${LOGFILE}" 
                 ;;
        * ) echo [$(date +"%F %X")]" ${msg_str}" | tee -a "${LOGFILE}" 
            ;;
    esac
}


function check_file_exists {
    local lv_target_file="$1"

    test -f "${lv_target_file}" || { ilogger "err" "Expected file ${lv_target_file} does not exist !" ; exit 1; }
}


function ensure_dir {
    local lv_des_abs_path="$1"
    local lv_dir_owner="${2:-root}"

    if [ ! -d "${lv_des_abs_path}" ];
    then
        sudo mkdir -p "${lv_des_abs_path}"
        sudo chown ${lv_dir_owner}:${lv_dir_owner} "${lv_des_abs_path}"
        test $? -eq 0 || { ilogger "err" "FAIL to create directory ${lv_des_abs_path} !" ; exit 1; }
        ilogger "suc" "Create directory ${lv_des_abs_path} and set its owner to ${lv_dir_owner} ."
    else
        ilogger "warn" "Directory ${lv_des_abs_path} already exists, skip."
    fi
}


function add_gpg_key {
    local lv_gpg_key_url="$1"

    which curl
    test $? -eq 0 || { ilogger "err" "No curl command found in this host !" ; exit 1; }

    curl -fsSL "${lv_gpg_key_url}" | sudo apt-key add -
    test $? -eq 0 || { ilogger "err" "FAIL to add GPG key from URL ${lv_gpg_key_url} !" ; exit 1; }
}


function add_apt_repository {
    local lv_apt_repo="$1"

    sudo add-apt-repository "${lv_apt_repo}"
    test $? -eq 0 || { ilogger "err" "FAIL to add apt repository ${lv_apt_repo} !" ; exit 1; }
}


function update_package_source {
    sudo apt-get update -y
}


function install_package {
    local lv_pkg_name="$1"

    sudo apt-get install -y "${lv_pkg_name}"
    test $? -eq 0 || { ilogger "err" "FAIL to install package ${lv_pkg_name} !" ; exit 1; }
}


function install_packages {
    local lv_pkg_names_file="$1"

    ilogger "Install packages from list ${lv_pkg_names_file}"
    while read -u6 each_pkg ;
    do
        install_package "${each_pkg}"
    done 6<${lv_pkg_names_file}
}


function uninstall_package {
    local lv_pkg_name="$1"

    sudo apt-get remove -y "${lv_pkg_name}"
    test $? -eq 0 || { ilogger "warn" "Not remove package ${lv_pkg_name} ." ; exit 0; }
}


function uninstall_packages {
    local lv_pkg_names_file="$1"

    ilogger "Remove packages from list ${lv_pkg_names_file}"
    while read -u6 each_pkg ;
    do
        uninstall_package "${each_pkg}"
    done 6<${lv_pkg_names_file}
}

