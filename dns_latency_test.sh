
#/bin/bash

if [ $# -lt 2 ]
then
  echo "#### You did not provide 2 arguments with the script."
  echo "#### Run the script again first providing the ip address of the name server"
  echo "#### and secondly provide the FQDN of any host in dns."
  echo "#### ie: dns_latency_test.sh 172.16.1.1 my-server.domain.net"
  exit 1
fi

if [ $# -eq 3 ]
then
  cycles=$3
else
  cycles=1000
fi

nameserver01=$1
fqdn_of_a_server=$2
slow_entries=0
max_slow=0

date_now=$(date +%Y%m%d_%H%M%S)
file_ext=".log"
touch /tmp/dns_latency_test_$fqdn_of_a_server$()_$date_now.log
fqfl="/tmp/dns_latency_test_$fqdn_of_a_server$()_$date_now$file_ext"

echo "Testing $nameserver01 $cycles times with hostname: \
$fqdn_of_a_server" | tee -a $fqfl

for i in `seq 1 $cycles`
do
  echo -n "$(date +%H:%M:%S)  " | tee -a $fqfl
  log_entry=`dig @$nameserver01 $fqdn_of_a_server | tr -d ";" | grep Query`
  if [ ! $? -eq 0 ]
  then
    echo "Query of $fqdn_of_a_server from $nameserver01 failed. Exiting." \
    | tee -a $fqfl
    exit 1
  fi
  echo $log_entry | tee -a $fqfl

  latency=`echo $log_entry | awk '{ print $3 }'`
  if [ $latency -gt $max_slow ]
  then
    max_slow=$latency
  fi

  query_time=`echo $log_entry | awk '$3 >= 30{ print "1" } 
  $3 <= 29{ print "0" }'`
  slow_entries=$((query_time+slow_entries))
  sleep 1
done

echo ""
echo "Test complete. $slow_entries out of $cycles tests were slow." | tee -a $fqfl
echo "The slowest response found was $max_slow ." | tee -a $fqfl
echo "Check out the log file located at $fqfl"
