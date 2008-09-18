#!/bin/bash

# Login to the master node of a cluster
ssh $SSH_OPTS root@`$bin/cloud master`
