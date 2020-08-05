# Define Variables for the Configurations
export APPSECRET=$(uuidgen)
export APPSECRET_DESCRIPTION=secret
export APPNAME="Cloud-One-Conformity"

# Ask User Input for the App Registration Name
echo " "
echo "Hello, Thank you for trying this script out.
We're configuring your Azure Account to work with Cloud One Conformity, this might take several minutes depending of how many subscriptions you have."

# Create App Registration
az ad app create --only-show-errors --display-name $APPNAME --password $APPSECRET --credential-description $APPSECRET_DESCRIPTION --required-resource-accesses @manifest.json > /dev/null

# Export App Registration ID and Active Directory ID
export ADID=`az account show --only-show-errors --query tenantId --output tsv`
export APPID=`az ad app list --only-show-errors --display-name $APPNAME | grep appId | cut -d ":" -f2 | grep -o '".*"' | sed 's/^"\(.*\)".*/\1/'`

# Create a Service Principal for the App Registration
az ad sp create --only-show-errors --id $APPID > /dev/null

# Export All Subscriptions ID's to an Array and Count to a Variable
az account list --only-show-errors --refresh > /dev/null
export SUBSCRIPTIONS=(`az account list --only-show-errors | grep id | cut -d ":" -f2 | grep -o '".*"' | sed 's/^"\(.*\)".*/\1/'`)
NUMSUBS=${#SUBSCRIPTIONS[@]}

 # Loop to add each one of the Subscriptions
 i=0
 for (( i; i<=$NUMSUBS; i++ ))
 do  
    az role assignment create --only-show-errors --role Reader --assignee $APPID --scope /subscriptions/${SUBSCRIPTIONS[i]} > /dev/null
    sleep 5
 done

# Print All the Information
echo "Here the information that you'll need to use to finish the integration"
echo " "
echo 'Active Directory ID: '$ADID
echo 'Application ID: '$APPID
echo 'Application Secret :'$APPSECRET
echo " "