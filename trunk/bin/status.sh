#!/bin/bash

# Get the status of the cloud
if [ -f $instances ]; then
    cat $instances | xargs ec2din
else
    echo "No known instances running for this cloud, describing all EC2 instances..."
    ec2din
fi
