#!/bin/bash


PUB_IP_ADDRESS="$1"
TROJAN_PASSWORD="$2"

TROJAN_CONF_DIR='/etc/trojan'


WRKROOT="$PWD"
CONFDIR="${WRKROOT}/conf"
TPLDIR="${WRKROOT}/templates"
TMPDIR="${WRKROOT}/tmp"

. "${CONFDIR}/env.sh"
. "${CONFDIR}/util.sh"


if [ $# -ne 2 ];
then
    ilogger "err" "Usage: run.sh YourPublicIPAddress YourTrojanPassword"
    exit 1
fi

# Install neccessary tools
ilogger "msg" "Install neccessary tools."
install_packages "${CONFDIR}/pre_requirements.lst"


# Install docker
ilogger "msg" "Uninstall docker if it exists."
uninstall_packages "${CONFDIR}/remove_old_docker.lst"

ilogger "msg" "Install docker."
update_package_source
add_gpg_key "${GPG_KEY_DOCKER_UBUNTU}"
add_apt_repository "${APT_REPO_DOCKER_UBUNTU}"
update_package_source
install_packages "${CONFDIR}/install_docker.lst"
sudo usermod -aG docker "$(whoami)"


# Configure UFW firewall
ilogger "warn" "Configure UFW firewall."
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw allow 443
sudo ufw enable
sudo systemctl enable ufw


# Create self-sign certificates
ilogger "msg" "Prepare template files for self-sign certificates."
ensure_dir "${TMPDIR}" "$(whoami)"
check_file_exists "${TPLDIR}/ca.txt"
sed 's/[YourPublicIPAddress]/'${PUB_IP_ADDRESS}'/g' "${TPLDIR}/ca.txt" > "${TMPDIR}/ca.txt"
check_file_exists "${TPLDIR}/server.txt"
sed 's/[YourPublicIPAddress]/'${PUB_IP_ADDRESS}'/g' "${TPLDIR}/server.txt" > "${TMPDIR}/server.txt"

ilogger "msg" "Generate self-sign certificate files for Trojan."
certtool --generate-privkey --outfile "${TMPDIR}/ca-key.pem"
certtool --generate-self-signed --load-privkey "${TMPDIR}/ca-key.pem" --template "${TMPDIR}/ca.txt" --outfile "${TMPDIR}/ca-cert.pem"
certtool --generate-privkey --outfile "${TMPDIR}/trojan-key.pem"
certtool --generate-certificate --load-privkey "${TMPDIR}/trojan-key.pem" --load-ca-certificate "${TMPDIR}/ca-cert.pem" --load-ca-privkey "${TMPDIR}/ca-key.pem" --template "${TMPDIR}/server.txt" --outfile "${TMPDIR}/trojan-cert.pem"


# Prepare trojan configuration files
ensure_dir "${TROJAN_CONF_DIR}"
ilogger "msg" "Generate configuration files for Trojan."
check_file_exists "${TMPDIR}/trojan-cert.pem"
sudo cp "${TMPDIR}/trojan-cert.pem" "${TROJAN_CONF_DIR}/trojan-cert.pem"
check_file_exists "${TMPDIR}/trojan-key.pem"
sudo cp "${TMPDIR}/trojan-key.pem" "${TROJAN_CONF_DIR}/trojan-key.pem"
check_file_exists "${TPLDIR}/trojan_server_config.json"
sed 's/YourPasswordHere/'${TROJAN_PASSWORD}'/g' "${TPLDIR}/trojan_server_config.json" > "${TMPDIR}/config.server.json"
sudo cp "${TMPDIR}/config.server.json" "${TROJAN_CONF_DIR}/config.json"
check_file_exists "${TPLDIR}/trojan_client_config.json"
sed -e 's/YourPublicIPAddress/'${PUB_IP_ADDRESS}'/g' -e 's/YourPasswordHere/'${TROJAN_PASSWORD}'/g' "${TPLDIR}/trojan_client_config.json" > "${TMPDIR}/config.client.json"


# Use trojan with docker
ilogger "msg" "Start a docker container of Trojan server."
docker pull teddysun/trojan
docker run -d --name trojan --restart always -p 443:443 -v /etc/trojan:/etc/trojan teddysun/trojan
sudo systemctl enable docker

# Finish
ilogger "suc" "Finish installation of Trojan server."

echo "Tips:"
echo "1. Trojan server is running on docker with the name trojan, listening on port 443."
echo "   Its configuration in the file /etc/trojan/config.json ."
echo "2. Copy ${TMPDIR}/config.client.json to the client side, rename it to config.json ."
echo "   Copy ${TMPDIR}/ca-cert.pem to the client side too."

