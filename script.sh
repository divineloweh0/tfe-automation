#!/bin/bash
sudo yum update -y

hostname=$(hostname)
#ip=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
#sudo echo "$ip   $hostname" >> /etc/hosts
./uninstall.sh
sudo yum remove docker-ce -y
sudo rm -rf /etc/docker
sudo rm -rf /var/lib/docker
sudo yum install docker-ce -y
sudo systemctl start docker

sudo rm -rf /root/certback
sudo rm -rf /etc/cert
sudo rm -rf /etc/settings.json
sudo rm -rf /etc/replicated.conf
sudo rm -rf /etc/payload.json

sudo mkdir /etc/cert
sudo mkdir /root/certback

sudo systemctl stop firewalld
sudo systemctl disable firewalld
set enforce 0
sudo openssl req -newkey rsa:4096 \
            -x509 \
            -sha256 \
            -days 3650 \
            -nodes \
            -out /root/certback/loweh.crt \
            -keyout /root/certback/loweh.key \
            -subj "/C=us/ST=texas/L=texas/O=IT/OU=IT/CN=$hostname"

sudo cp /root/certback/* /etc/cert
sudo cp license.rli /etc/cert
sudo cat << EOF >> /etc/settings.json
{
  "hostname": {
        "value": "$HOSTNAME"
    },
    "disk_path": {
        "value": "/opt/terraform-enterprise"
    },
    "enc_password": {
        "value": "$ENC_PASSWORD"
    },
    "pg_dbname": {
        "value": "$PG_DBNAME"
    },
  "pg_password": {
        "value": "$PG_PASSWORD"
  },
  "pg_user": {
        "value": "$PG_USER"
  },
  "gcs_bucket": {
        "value": "$GCS_BUCKET"
  },
  "gcs_credentials": {
        "value": "$GCS_CREDENTIALS"
  },
  "gcs_project": {
        "value": "$GCS_PROJECT"
  }
  
  }
EOF

sudo cat << EOF >> /etc/replicated.conf
{
    
    "DaemonAuthenticationType":     "password",
    "DaemonAuthenticationPassword": "$REPLICATED_PASSWORD",
    "TlsBootstrapType":             "$TLS_SERVER_PATH",
    "TlsBootstrapHostname":         "$TLS_SERVER_HOSTNAME",
    "TlsBootstrapCert":             "/etc/cert/loweh.crt",
    "TlsBootstrapKey":              "/etc/cert/loweh.key",
    "BypassPreflightChecks":        true,
    "ImportSettingsFrom":           "/etc/settings.json",
    "LicenseFileLocation":          "/etc/cert/license.rli"


}
EOF

sudo cat << EOF >> /etc/payload.json
{
  "username": "$FIRST_USER",
  "email": "$FIRST_USER_EMAIL",
  "password": "$FIRST_USER_PASSWORD"
}
EOF

curl -o install.sh https://install.terraform.io/ptfe/stable
sudo chmod +x install.sh
echo "testing enteprise readiness"
sudo ./install.sh
echo "Completed"
