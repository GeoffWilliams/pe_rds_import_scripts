#!/bin/bash
#
# Import AND SWITCH DATABASES TO USE the amazon RDS CA authority file, 
# downloading a CA file based on the instructions at:
# 	http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html
# Which refer to a file https://rds.amazonaws.com/doc/rds-ssl-ca-cert.pem at time
# of writing

CA_DIR="/etc/puppetlabs/amazon_ca"
CA_FILE="rds-ssl-ca-cert.pem"
AMAZON_CA_FILE="${CA_DIR}/${CA_FILE}"
CA_BASE_URL="https://rds.amazonaws.com/doc/"
CA_URL="${CA_BASE_URL}/${CA_FILE}"
VENDORED_CA_FILE="/etc/puppetlabs/puppet/ssl/certs/ca.pem"

mkdir -p $CA_DIR
wget -O $AMAZON_CA_FILE $CA_URL

./change_db_conf_string.sh $VENDORED_CA_FILE $AMAZON_CA_FILE
