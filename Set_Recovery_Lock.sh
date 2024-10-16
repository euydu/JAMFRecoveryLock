#!/bin/bash
# Created by Emre Uydu - System Engineer
# emreuydu@gmail.com
# Contact to me for more info
#########################################################################
#Parameters
APIUsername=""
APIuserpassword=""
JAMFServer="" 
#########################################################################
#DO NOT CHANGE BELOW CODES
#########################################################################
#JAMF API Token
JAMFAPIToken=$(curl -X POST -u $APIUsername:$APIuserpassword -s $JAMFServer/api/v1/auth/token | plutil -extract token raw -)
DeviceSerialNumber=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
echo $JAMFAPIToken
#Determine Device JSS ID
DeviceJSSID=$(curl -X GET -H "Authorization: Bearer $JAMFAPIToken" "$JAMFServer/JSSResource/computers/serialnumber/$DeviceSerialNumber" -H "accept: text/xml" | xmllint --xpath "/computer/general/id/text()" -)
#Create JSON Data
function DeviceJSONData {
	curl -X 'GET' \
	''$JAMFServer'/api/v1/computers-inventory/'$DeviceJSSID'?section=GENERAL' \
	-H 'accept: application/json' \
	-H 'Authorization: Bearer '$JAMFAPIToken''
}
FileName="/private/tmp/DeviceData.json"
DeviceJSONData > $FileName
#Filter Device Management ID
DeviceManagementID=$(cat $FileName | grep -o '"[^"]*"\s*:\s*"[^"]*"' | grep -E '^"(managementId)"')
ManamegementIDKey=$(echo $DeviceManagementID | cut -b 19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54)
echo $ManamegementIDKey
#NewPassword #30 Digit
MinValue=100000
MaxValue=999999
Part1=$(($RANDOM%($MaxValue-$MinValue+1)+$MinValue))
Part2=$(($RANDOM%($MaxValue-$MinValue+1)+$MinValue))
Part3=$(($RANDOM%($MaxValue-$MinValue+1)+$MinValue))
Part4=$(($RANDOM%($MaxValue-$MinValue+1)+$MinValue))
Part5=$(($RANDOM%($MaxValue-$MinValue+1)+$MinValue))
NewRecoveryPassword=$Part1$Part2$Part3$Part4$Part5
echo $NewRecoveryPassword
MDMCommand="$JAMFServer/api/v2/mdm/commands"
#Set Recovery Lock
curl --location --request POST ''$MDMCommand'' --header 'Authorization: Bearer '$JAMFAPIToken'' \
--header 'Content-Type: application/json' \
--data-raw '{
	"clientData": [
		{
			"managementId" : "'$ManamegementIDKey'",
			"clientType": "COMPUTER"
		}
	],
	"commandData": {
		"commandType": "SET_RECOVERY_LOCK",
		"newPassword": "'$NewRecoveryPassword'"
	}
}'
rm -R $FileName
