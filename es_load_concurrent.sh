#####CHANGE ME#################

DATA_FILE=mock_data5
numParallelLoads=8

################################


numLines=`wc -l $DATA_FILE | awk -F" " '{print $1}'`
expCount=$(($numLines/2*$numParallelLoads))        ## Accounts for the line indicating where to load the data 
echo ""
echo "Expected record count: " $expCount
echo ""

varStart=`date +%M:%S`
echo "Delete Load Gen Index"
curl -u elastic:bzMPOxjd78uhLcKln1vbBTuv -X DELETE 'https://load-gen-test.es.us-east-2.aws.elastic-cloud.com/load_gen/'
echo ""

echo ""
echo "Create New Load Gen Index"
curl -u elastic:bzMPOxjd78uhLcKln1vbBTuv -H 'Content-Type: application/x-ndjson' -X PUT 'https://load-gen-test.es.us-east-2.aws.elastic-cloud.com/load_gen/' -d'{"settings": {"number_of_shards": 6 }}'
echo ""
echo ""


for i in $( seq 1 $numParallelLoads )
do

nohup curl -u elastic:bzMPOxjd78uhLcKln1vbBTuv -H 'Content-Type: application/x-ndjson' -XPOST 'https://load-gen-test.es.us-east-2.aws.elastic-cloud.com/load_gen/_bulk?pretty' --data-binary @$DATA_FILE -o /dev/null --silent &
pids[${i}]=$!

done

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
curl -u elastic:bzMPOxjd78uhLcKln1vbBTuv -H 'Content-Type: application/x-ndjson' -X GET 'https://load-gen-test.es.us-east-2.aws.elastic-cloud.com/load_gen/_count'
echo ""
echo ""
echo "Index Size in Bytes"
curl -u elastic:bzMPOxjd78uhLcKln1vbBTuv -H 'Content-Type: application/x-ndjson' -X GET 'https://load-gen-test.es.us-east-2.aws.elastic-cloud.com/load_gen/_stats/store'
echo ""
echo ""
