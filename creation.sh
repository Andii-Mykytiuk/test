#!/bin/bash

sec_gr=$(aws ec2 create-security-group --group-name my-sg --description "my own")

echo "created security group $sec_gr"

aws ec2 authorize-security-group-ingress --group-name my-sg --protocol tcp --port 80 --cidr 195.114.97.93/32

aws ec2 authorize-security-group-ingress --group-name my-sg --protocol tcp --port 22 --cidr 195.114.97.93/32

aws ec2 run-instances --image-id ami-08962a4068733a2b6 --count 1 --instance-type t2.micro --key-name newconnection --security-groups my-sg --user-data file://nging.sh
# Wait for the instance to be created, running, and passed status ch
aws ec2 wait instance-status-ok

public_ip=$(aws ec2 describe-instances --filters --query Reservations[*].Instances[*].[PublicIpAddress] --output text )

echo "Publick Ip is $public_ip" 
