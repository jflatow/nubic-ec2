#!/bin/bash

# Terminate a cluster.
echo "Terminating Hadoop instances:"
cat $instances

ec2-terminate-instances `cat $instances`
rm $instances
rm $master
rm $slaves