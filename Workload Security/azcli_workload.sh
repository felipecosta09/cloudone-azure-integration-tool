# Define Variables for the Configurations
export APPSECRET=$(uuidgen)
export APPSECRETDESCRIPTION="secret"
export APPNAME="Cloud-One-Workload-Security"

# Ask User Input for the App Registration Name
echo " "
echo 'What is the name of your Cloud One Tenant?'
read CLOUDONETENANT
echo " "
echo 'What is your Cloud One Username?'
read CLOUDONEUSER
echo " "
echo 'What is your Cloud One Password?'
read CLOUDONEPASSWORD
echo " "
echo "We're configuring your Azure Account to work with Cloud One Workload Security, this might take several minutes depending of how many subscriptions you have."

# Create App Registration
az ad app create --only-show-errors --display-name $APPNAME --password $APPSECRET --credential-description $APPSECRETDESCRIPTION  > /dev/null

# Export App Registration ID and Active Directory ID
export ADID=`az account show --only-show-errors --query tenantId --output tsv`

export APPID=`az ad app list --only-show-errors --display-name $APPNAME | grep appId | cut -d ":" -f2 | grep -o '".*"' | sed 's/^"\(.*\)".*/\1/'`

# Create a Service Principal for the App Registration
az ad sp create --id $APPID > /dev/null

# Export All Subscriptions ID's to an Array and Count to a Variable
az account list --only-show-errors --refresh > /dev/null
export SUBS=(`az account list --only-show-errors | grep id | cut -d ":" -f2 | grep -o '".*"' | sed 's/^"\(.*\)".*/\1/'`)
export NUMSUBS=${#SUBS[@]}

# Cloud One API Key Generation
export TOKEN=`curl -s -d '{ "dsCredentials": { "tenantName": "'"$CLOUDONETENANT"'", "userName": "'"$CLOUDONEUSER"'", "password": "'"$CLOUDONEPASSWORD"'" } }' -H "Content-Type: application/json" https://app.deepsecurity.trendmicro.com/rest/authentication/login | sed 's/%//'`

 # Loop to add each one of the Subscriptions and Add the information in Cloud One Workload Security using the API
az role assignment create --only-show-errors --role Reader --assignee $APPID --scope /subscriptions/${SUBS[i]} > /dev/null
# curl -s -X POST https://cloudone.trendmicro.com/rest/proxies -H 'Accept: application/json' -H "Content-Type: application/json" -H 'Cookie: sID='$TOKEN'' -d '{ "CreateProxyRequest": { "proxy": { "name": "${SUBS[i]}", "address": "1.1.1.1", "port": 80, "protocol": "http", "authenticated": false } } }'
# curl POST https://app.deepsecurity.trendmicro.com/rest/cloudaccounts -H 'Accept: application/json' -H "Content-Type: application/json" -d '{ "createCloudAccountRequest": { "cloudAccountElement": { "cloudType": "AZURE_ARM", "name": "'"${SUBS[i]}"'", "subscriptionName": "'"${SUBS[i]}"'", "subscriptionId": "'"${SUBS[i]}"'", "azureAdTenantId": "'"$ADID"'", "azureAdApplicationId": "'"$APPID"'", "azureAdApplicationPassword": "'"$APPSECRET"'" }, "sessionId": "'"$TOKEN"'" } }'
# curl POST https://app.deepsecurity.trendmicro.com/rest/cloudaccounts -H 'Accept: application/json' -H "Content-Type: application/json" -d '{ "createCloudAccountRequest": { "cloudAccountElement": { "cloudType": "AZURE_ARM", "name": "'"$SUBS"'", "subscriptionId": "'"$SUBS"'", "azureAdTenantId": "'"$ADID"'", "azureAdApplicationId": "'"$APPID"'", "azureAdApplicationPassword": "'"$APPSECRET"'" }, "sessionId": "'$TOKEN'" } }'

# echo $TOKEN
# echo $APPSECRET
# echo $ADID
# echo $APPID
# echo $SUBS
# echo $NUMSUBS
# echo $CLOUDONETENANT
# echo $CLOUDONEUSER
# echo $CLOUDONEPASSWORD


#  i=0
#  for (( i; i<=$NUMSUBS; i++ ))
#  do  
#    echo ${SUBS[i]}
#     az role assignment create --only-show-errors --role Reader --assignee $APPID --scope /subscriptions/${SUBS[i]} > /dev/null
#     curl -s -X POST https://app.deepsecurity.trendmicro.com/rest/cloudaccounts -H 'Accept: application/json' -H "Content-Type: application/json" -d '{ "createCloudAccountRequest": { "cloudAccountElement": { "cloudType": "AZURE_ARM", "name": "efwefwef", "subscriptionId": "'"${SUBS[i]}"'", "azureAdTenantId": "'"$ADID"'", "azureAdApplicationId": "'"$APPID"'", "azureAdApplicationPassword": "'"$APPSECRET"'" }, "sessionId": "'$TOKEN'" } }'
#  done

# Close API Session
# curl -X DELETE https://cloudone.trendmicro.com/rest/session -H 'Cookie: sID='/$TOKEN''

# Print All the Information
echo " "
echo "The process is done! Go check your Azure Accounts in Cloud One Workload Security."
echo " "