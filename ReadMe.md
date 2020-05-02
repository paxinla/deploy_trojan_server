# Deploy Trojan Server

![Bash](https://img.shields.io/static/v1?label=terminal&message=Bash&color=blue&logo=gnubash)
![trojan](https://img.shields.io/static/v1?label=Trojan&message=in%20Docker%20on%20Ubuntu&color=orange&logo=docusign)

----------

This is a set of bash scripts for installing [Trojan](https://github.com/trojan-gfw/trojan) server on a Ubuntu server with Docker. It generates necessary self-signed certificate files. No domain name required.

## Requirements

- OS: Ubuntu
- OS User: Can use sudo without input password

## Usage

On the server side, Execute command in this directory :

```sh
$ make install IP=your-server-public-ip PASSWORD=your-trojan-connect-password
```

After finishing the installation, you should copy the files, config.client.json and ca-cert.pem, under directory tmp, to your trojan client directory. And rename config.client.json to config.json .

Use docker command to manage the trojan server:

```sh
$ docker stop trojan

$ docker start trojan
```

Changing the server port needs to modify config.json file on both server side and client side, and add a relervant rule on ufw firewall on the server side.
