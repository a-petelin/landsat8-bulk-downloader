#!/bin/bash
#jq="/c/Users/MstB/Downloads/jq-win64.exe"/usr/bin/jq
jq="/usr/bin/jq"
LOGIN=$1
PWD=$2
#PWD='Thtnbrb|Nfv|Ud0plb|'

FORM=$(curl -c login.cook -b login.cook -L 'https://earthexplorer.usgs.gov/inventory/documentation/json-api')
CSTOKEN=$(echo $FORM | sed -e 's/>/>\
/g' | grep '<input' | grep 'csrf_token' | awk -F '"' '{print $6}' | sed -e 's/=/%3d/g' | sed -e 's/\//%2f/g')
NCFINFO=$(echo $FORM | sed -e 's/>/>\
/g' | grep '<input' | grep '__ncforminfo' | awk -F '"' '{print $6}' | sed -e 's/=/%3d/g' | sed -e 's/\//%2f/g')

DATA=$(echo 'username='$LOGIN'&password='$PWD'&csrf_token='$CSTOKEN'&__ncforminfo='$NCFINFO | sed -e 's/|/%7c/g')
curl -d $DATA -c login.cook -b login.cook 'https://ers.cr.usgs.gov/login/'

DATA=$(curl -d 'jsonRequest={"username": "'$LOGIN'", "password": "'$PWD'", "authType": "EROS", "catalogId": "EE"}' https://earthexplorer.usgs.gov/inventory/json/v/1.4.0/login)
APIKEY=$(echo $DATA | $jq -r ".data")

MONTHS=$(echo '6,7,8' | sed -e 's/,/%2c/g')
BEGIN=2015-01-01
END=2020-01-01
COUNT=100

DATA=$(curl 'https://earthexplorer.usgs.gov/inventory/json/v/1.4.0/search?jsonRequest=%7b%22apiKey%22:%22'$APIKEY'%22,%22datasetName%22:%22LANDSAT_8_C1%22,%22maxCloudCover%22:30,%22minCloudCover%22:0,%22temporalFilter%22:%7b%22startDate%22:%22'$BEGIN'%22,%22endDate%22:%22'$END'%22%7d,%22months%22:['$MONTHS'],%22maxResults%22:'$COUNT',%22additionalCriteria%22:%7b%22filterType%22:%22between%22,%22fieldId%22:25171,%22firstValue%22:19,%22secondValue%22:90%7d,%22spatialFilter%22:%7b%22filterType%22:%22mbr%22,%22lowerLeft%22:%7b%22latitude%22:53,%22longitude%22:0%7d,%22upperRight%22:%7b%22latitude%22:55,%22longitude%22:170%7d%7d,%22includeUnknownCloudCover%22:false%7d')
RESULT=$(echo $DATA | $jq -j '.data.results[].entityId + " "')
for ent in $RESULT; do curl -c login.cook -b login.cook -L 'https://earthexplorer.usgs.gov/order/addbulkscene?scenes='$ent'&collection_id=12864&originator=INVSVC' 2> /dev/null; done
DATA=$(curl 'https://earthexplorer.usgs.gov/inventory/json/v/1.4.0/logout?jsonRequest=%7b%22apiKey%22:%22'$APIKEY'%22%7d')
echo 'DATA=' $DATA | jq -C
