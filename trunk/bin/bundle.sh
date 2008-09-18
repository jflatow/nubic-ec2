#!/bin/bash

cat > $bin/bundle_remote.sh <<EOF
#!/bin/bash

echo > ~/.ssh/known_hosts
echo > ~/.ssh/authorized_keys
rm -rf /tmp/hadoop*
find / -name \*~ | xargs rm -f
history -c
ec2-bundle-vol -d /mnt -k /mnt/pk-*.pem -c /mnt/cert-*.pem -u $AWS_ACCOUNT_ID -p $IMAGE_NAME -r i386 && \
ec2-upload-bundle -b $S3_BUCKET -m /mnt/$IMAGE_NAME.manifest.xml -a $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY
EOF

# Copy files to the master
scp $SSH_OPTS $EC2_KEYDIR/pk-*.pem root@`$bin/cloud master`:/mnt/
scp $SSH_OPTS $EC2_KEYDIR/cert-*.pem root@`$bin/cloud master`:/mnt/
scp $SSH_OPTS $bin/bundle_remote.sh root@`$bin/cloud master`:/mnt/

# Perform the bundle (note we do not terminate the cloud, which so far has not been a problem)
ssh $SSH_OPTS root@`$bin/cloud master` "cd /mnt; chmod 755 bundle_remote.sh; ./bundle_remote.sh" && \
ec2dim | grep $S3_BUCKET | grep $IMAGE_NAME | awk '{print $2}' | ec2-deregister - && \
ec2-register $S3_BUCKET/$IMAGE_NAME.manifest.xml

# Cleanup
rm $bin/bundle_remote.sh