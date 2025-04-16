#/bin/bash

if [ $# -lt 2 ]
then
  echo "#### You did not provide 2 arguments with the script."
  echo "#### Run the script again first providing the ip address of the name server"
  echo "#### and secondly provide the FQDN of any host in dns."
  echo "#### ie: dns_latency_test.sh 172.16.1.1 my-server.domain.net"
  exit 1
fi

date_now=$(date +%Y%m%d_%H%M%S)
file_ext=".log"
touch /tmp/dns_latency_test_$date_now.log
fqfl="/tmp/dns_latency_test_$date_now$file_ext"

nameserver01=$1
fqdn_of_a_server=$2

for i in {1..1000}
do
  echo -n "$(date +%H:%M:%S)  "
  dig @$nameserver01 $fqdn_of_a_server | grep Query | tr -d ";" | tee -a $fqfl
  sleep 1
done

echo ""
echo "Test complete. Check out the log file located at $fqfl"
