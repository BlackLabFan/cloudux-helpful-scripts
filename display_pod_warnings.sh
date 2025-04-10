#!/bin/bash
# This program takes in one positional argument: the duration to test.
# ie: 10m 1h yesterday. if no duration is supplied 2m is used.

if [ -n "$1" ]
then
  my_range=$1
else
  my_range=2m
fi

error_flag=0

for i in `sudo kubectl get pods | awk '{print $1}'`
do
  total_entries="$(kubectl logs $i --since=my_range | grep -ce WARN -ce ERROR)"
  if [ $total_entries -gt 0 ]
  then
    error_flag=1
  fi
  echo "FOUND $total_entries ERRORS AND WARNINGS FOR: $i!"
  kubectl logs $i --since=my_range | grep -ie error -ie warn -A 2
  echo ""
done

if [ error_flag -eq 0 ]
then
  echo "No errors or warnings found in any pod for the $my_range duration specified."
fi



