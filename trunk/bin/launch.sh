#!/bin/bash

# Launch an EC2 cluster of Hadoop instances.

ec2-describe-group | grep $GROUP > /dev/null
if [ ! $? -eq 0 ]; then
  echo "Creating group $GROUP"
  ec2-add-group $GROUP -d "Group for Hadoop clusters."
  ec2-authorize $GROUP -p 22    # ssh
  ec2-authorize $GROUP -p 50030 # JobTracker web interface
  ec2-authorize $GROUP -p 50060 # TaskTracker web interface
  ec2-authorize $GROUP -p 50070 # NameNode web interface
  ec2-authorize $GROUP -o $GROUP -u $AWS_ACCOUNT_ID 
fi

echo "Finding AMI"
AMI_IMAGE=`ec2-describe-images -a | grep $S3_BUCKET | grep $IMAGE_NAME | grep available | awk '{print $2}'`

echo "Starting cluster with AMI $AMI_IMAGE"
RUN_INSTANCES_OUTPUT=`ec2-run-instances $AMI_IMAGE -n $NUM_INSTANCES -g $GROUP -k $KEY_NAME | grep INSTANCE | awk '{print $2}'`
echo $RUN_INSTANCES_OUTPUT > $instances
echo | tee $slaves $master
for instance in $RUN_INSTANCES_OUTPUT; do
    printf "Waiting for instance $instance to start"
    while true; do
        printf "."
        HOSTNAMES=`ec2-describe-instances $instance | grep running | awk '{print $4"\t"$5}'`
        HOSTNAME=`printf "$HOSTNAMES" | cut -f 1`
        if [ ! -z $HOSTNAME ]; then
            printf "$HOSTNAMES\n" >> $slaves
            echo "started as $HOSTNAME, copying private key"
            scp $SSH_OPTS $PRIVATE_KEY_PATH root@$HOSTNAME:~/.ssh/id_rsa
            ssh $SSH_OPTS root@$HOSTNAME "chmod 600 ~/.ssh/id_rsa"
            break;
        fi
        sleep 1
    done
done

echo "Appointing master"
ec2-describe-instances | grep INSTANCE | grep running | awk '{if ($8 == 0 || $7 == 0) print $4"\t"$5}' > $master
MASTER_EC2_HOST=`$bin/cloud master`
MASTER_EC2_INTERNAL=`cut -f 2 $master`

echo "Creating slaves file and copying to master"
sed -i '' -e "/$MASTER_EC2_HOST/d" $slaves
cat $slaves | ssh $SSH_OPTS root@$MASTER_EC2_HOST "cut -f 2 > $IMAGE_HADOOP_HOME/conf/slaves"

echo "Initializing slaves"
for slave in `cut -f 1 $slaves`; do
    ssh $SSH_OPTS root@$slave "hadoop-init -n $NUM_INSTANCES $MASTER_EC2_INTERNAL"
done

echo "Initializing master"
ssh $SSH_OPTS root@$MASTER_EC2_HOST "hadoop-init -n $NUM_INSTANCES $MASTER_EC2_INTERNAL"
ssh $SSH_OPTS root@$MASTER_EC2_HOST "hadoop-master-init"

echo "Finished - check progress at http://$MASTER_EC2_HOST:50030/"
