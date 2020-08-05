#!/bin/bash
echo " "
echo "We're configuring your Azure Account to work with Cloud One Workload Security, this might take several minutes depending of how many subscriptions you have."
echo " "
export CLOUDONETENANT="Trend Micro GCC"
export CLOUDONEUSER="api"
export CLOUDONEPASSWORD="trendmicro"
export APPSECRET=$(uuidgen)
export APPNAME="Cloud-One-Workload-Security"
export APPSECRETDESCRIPTION="Secret"

# APPID=`az ad app create --only-show-errors --display-name $APPNAME --password $APPSECRET --credential-description $APPSECRETDESCRIPTION --query 'appId' --output tsv`
export ADID=`az account show --only-show-errors --query tenantId --output tsv`

SUBS=(`az account list --only-show-errors | grep id | cut -d ":" -f2 | grep -o '".*"' | sed 's/^"\(.*\)".*/\1/'`)
export NUMSUBS=${#SUBS[@]}
export TOKEN=`curl -s -d '{ "dsCredentials": { "tenantName": "'"$CLOUDONETENANT"'", "userName": "'"$CLOUDONEUSER"'", "password": "'"$CLOUDONEPASSWORD"'" } }' -H "Content-Type: application/json" https://cloudone.trendmicro.com/rest/authentication/login | sed 's/%//'`

for ((i=0; i<=$NUMSUBS; i++)); do
APPID=(`az ad sp create-for-rbac --only-show-errors -n $APPNAME --role Reader --scopes /subscriptions/${SUBS[i]} --query 'appId' --output tsv`) >nul 2>nul
curl -s https://cloudone.trendmicro.com/rest/cloudaccounts -H 'Accept: application/json' -H "Content-Type: application/json" -d '{ "createCloudAccountRequest": { "cloudAccountElement": { "cloudType": "AZURE_ARM", "name": "'"${SUBS[i]}"'", "subscriptionId": "'"${SUBS[i]}"'", "azureAdTenantId": "'"$ADID"'", "azureAdApplicationId": "'"$APPID"'", "azureAdApplicationPassword": "'"$APPSECRET"'" }, "sessionId": "'$TOKEN'" } }'
# az role assignment create --only-show-errors --role Reader --assignee $APPID --scope /subscriptions/${SUBS[i]} > /dev/null
done

echo " "
echo "The process is done! Go check your Azure Accounts in Cloud One Workload Security."
echo " "