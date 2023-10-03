#!/bin/bash

#Vars
RESOURCE_GROUP=$1
VAULT_NAME=$2

#check if resource group exists
RESOURCE_GROUP_EXIST=$( az group exists --name $RESOURCE_GROUP )

if [[ $RESOURCE_GROUP_EXIST == false ]]; then
    echo "$RESOURCE_GROUP does not exist"
    exit 0
fi

#Get backup jobs json from recovery services vault
AZ_BACKUP_RESULT=$( az backup job list --resource-group $RESOURCE_GROUP --vault-name $VAULT_NAME --output json )

#Loop over backup job json data
while read job_data; do
    job_status=$(jq -r '.properties.status' <<< "$job_data")
    vm_name=$(jq -r '.properties.entityFriendlyName' <<< "$job_data")
    vault_url_full=$(jq -r '.id' <<< "$job_data")
    #remove unwanted tail end of URL
    parsed_vault_url="${vault_url_full::-37}"

    #If backup job has failed, print vm name and vault name to slack message
    if [[ $job_status == "Failed" ]]; then
        printf "\n>:red_circle:  *$vm_name* backup in <https://portal.azure.com/#@HMCTS.NET/resource$parsed_vault_url|_*$VAULT_NAME*_> has $job_status" >> slack-message.txt
        failures_exist="true"
    fi
done < <(jq -c '.[]' <<< $AZ_BACKUP_RESULT)

#If no failures were found in json, mark vault as free from backup failures.
if [[ $failures_exist != "true" ]]; then
    printf "\n>:green_circle:  No failed backups in <https://portal.azure.com/#@HMCTS.NET/resource$parsed_vault_url|_*$VAULT_NAME*_>" >> slack-message.txt
fi

