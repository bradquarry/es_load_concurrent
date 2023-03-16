#####CHANGE ME#################

clusterHostname=https://load-gen-test.es.us-east-2.aws.elastic-cloud.com
elasticUser=elastic
elasticPw=bzMPOxjd78uhLcKln1vbBTuv

indexName=load_gen
numIndexShards=6

DATA_FILE=mock_data5
numParallelLoads=8


################################


numLines=`wc -l $DATA_FILE | awk -F" " '{print $1}'`
expCount=$(($numLines/2*$numParallelLoads))        ## /2 Accounts for the JSON line indicating where to load the data 
echo ""
echo "Expected record count: " $expCount
echo ""

# start fresh 
varStart=`date +%M:%S`
echo "Delete Load Gen Index"
curl -u $elasticUser:$elasticPw -X DELETE '$clusterHostname/$indexName/'
echo ""

#start fresh
echo ""
echo "Create New Load Gen Index"
curl -u $elasticUser:$elasticPw -H 'Content-Type: application/x-ndjson' -X PUT '$clusterHostname/$indexName/' -d'{"settings": {"number_of_shards": $numIndexShards }}'
echo ""
echo ""


for i in $( seq 1 $numParallelLoads )
do

nohup curl -u $elasticUser:$elasticPw -H 'Content-Type: application/x-ndjson' -XPOST '$clusterHostname/$indexName/_bulk?pretty' --data-binary @$DATA_FILE -o /dev/null --silent &
pids[${i}]=$!

done

#Gather and wait for all background pids
for pid in ${pids[*]}; do
  wait $pid
done

varEnd=`date +%M:%S`

secStart=`echo $varStart | awk -F: '{print ($1 * 60) + $2 }'`
secEnd=`echo $varEnd | awk -F: '{print ($1 * 60) + $2 }'`

echo "Seconds: " $(($secEnd-$secStart))
echo ""
echo "Index Record Count: " 
sleep 5
curl -u $elasticUser:$elasticPw -H 'Content-Type: application/x-ndjson' -X GET '$clusterHostname/$indexName/_count'
echo ""
echo ""
echo "Index Size in Bytes"
curl -u $elasticUser:$elasticPw -H 'Content-Type: application/x-ndjson' -X GET '$clusterHostname/$indexName/_stats/store'
echo ""
echo ""
