#!/bin/bash
 
 set -xe

# run rds + ec2 stack in private context + s3
# in ec2, and user-data with s3 wget to get sample.sql file
# load data in mysql from ec2 user-data

# TODO if there's already a snapshot, don't do the initial stack
terraform -chdir=initial_stack init -upgrade
terraform -chdir=initial_stack plan
terraform -chdir=initial_stack apply -auto-approve

# TODO wait for News from MySQL on EC2
EC2_IP=$(terraform -chdir=initial_stack output -json | jq -r ".ec2_ip.value")

echo "Waiting for News from MySQL..."
until curl -s -L http://${EC2_IP} | grep "News from MySQL"
do
    echo -n "."
    sleep 3
done

echo "Then visit: http://${EC2_IP}"
echo
sleep 5

# DEBUG
terraform -chdir=initial_stack output -json

LAST_DB_SNAPSHOT_ID=$(terraform -chdir=initial_stack output -json | jq -r ".initial_db_final_snapshot.value")
echo $LAST_DB_SNAPSHOT_ID

terraform -chdir=initial_stack destroy -auto-approve

# apply stack and load the snapshot
terraform init -upgrade
terraform plan
terraform apply -auto-approve -var db_snapshot_identifier=$LAST_DB_SNAPSHOT_ID

# proove that works within ec2
EC2_IP=$(terraform output -json | jq -r ".ec2_ip.value")

until curl -s -L http://${EC2_IP} | grep "News from MySQL"
do
    echo -n "."
    sleep 3
done

echo "Then visit: http://${EC2_IP}"