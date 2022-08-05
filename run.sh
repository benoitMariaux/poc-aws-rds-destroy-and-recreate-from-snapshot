#!/bin/bash
 
 set -e

LAST_DB_SNAPSHOT_ID=$(aws rds describe-db-snapshots \
  --query="max_by(DBSnapshots, &SnapshotCreateTime).DBSnapshotIdentifier" \
  --output text)

echo $LAST_DB_SNAPSHOT_ID

if [[ "$LAST_DB_SNAPSHOT_ID" == "None" ]]; then

    terraform -chdir=initial_stack init -upgrade
    terraform -chdir=initial_stack plan
    terraform -chdir=initial_stack apply -auto-approve

    EC2_IP=$(terraform -chdir=initial_stack output -json | jq -r ".ec2_for_mysql_loading_ip.value")

    echo "Waiting for News from MySQL..."
    until curl -s -L http://${EC2_IP} | grep "News from MySQL"
    do
        echo -n "."
        sleep 3
    done

    echo "Then visit: http://${EC2_IP}"

    LAST_DB_SNAPSHOT_ID=$(terraform -chdir=initial_stack output -json | jq -r ".initial_db_final_snapshot.value")
    echo $LAST_DB_SNAPSHOT_ID

    terraform -chdir=initial_stack destroy -auto-approve
fi

# apply stack and load the snapshot
terraform init -upgrade
terraform plan -var db_snapshot_identifier=$LAST_DB_SNAPSHOT_ID
terraform apply -auto-approve -var db_snapshot_identifier=$LAST_DB_SNAPSHOT_ID

# proove that works within ec2 and data from MySQL is still here
EC2_IP=$(terraform output -json | jq -r ".ec2_for_mysql_data_ip.value")

echo "Waiting for News from MySQL..."
until curl -s -L http://${EC2_IP} | grep "122" # 122 is the number of lines in customers table;
do
    echo -n "."
    sleep 3
done

echo "Then visit: http://${EC2_IP}"