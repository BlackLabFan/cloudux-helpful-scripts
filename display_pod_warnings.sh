#!/bin/bash
# This program takes in one positional argument: the duration to test.
# ie: 10m 1h. if no duration is supplied 2m is used.

# check for root
if ! [ $(id -u) -eq 0 ]
then
  echo "You forgot to say the magic word... sudo!"
  exit 1
fi

if [ -n "$1" ]
then
  my_range=$1
else
  my_range=2m
fi

error_flag=0

for i in `kubectl get pods | awk '{print $1}'`
do
  total_entries="$(kubectl logs $i --since=$my_range | grep -ce WARN -ce ERROR)"
  echo "FOUND $total_entries ERRORS AND WARNINGS FOR: $i!"
  if [ $total_entries -gt 0 ]
  then
    error_flag=1

    # print out all warning and error entries in the log file
    # may potentially need --all-containers=true
    kubectl logs $i --since=$my_range | awk '
    BEGIN{ do_print=0; new_line=1; print "" } /WARN/ || /ERR/{ do_print=1; new_line=1 } 
    /INFO/ && new_line==1{ do_print=0; print ""; new_line=0 } 
    do_print==1{ print $0 } END{ print "All done!"; print "" }'
  fi
done

if [ $error_flag -eq 0 ]
then
  echo "No errors or warnings found in any pod for the $my_range duration specified."
fi
