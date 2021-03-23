provider "aws" {
  access_key = "AKIAXHHJA3KTYOEFAU5O"
  secret_key = "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"
  region     = "us-east-2"
}

# Creating a VPC!
resource "aws_vpc" "custom" {

  # IP Range for the VPC
  cidr_block = "192.168.0.0/16"

  # Enabling automatic hostname assigning
  enable_dns_hostnames = true
  tags = {
    Name = "My-VPC"
  }
}

# Creating Public subnet!
resource "aws_subnet" "subnet1" {
  depends_on = [
    aws_vpc.custom
  ]

  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.custom.id

  # IP Range of this subnet
  cidr_block = "192.168.0.0/24"

  # Data Center of this subnet.
  availability_zone = "us-east-2a"

  # Enabling automatic public IP assignment on instance launch!
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
  }
}

# Creating Private subnet!
resource "aws_subnet" "subnet2" {
  depends_on = [
    aws_vpc.custom,
    aws_subnet.subnet1
  ]

  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.custom.id

  # IP Range of this subnet
  cidr_block = "192.168.1.0/24"

  # Data Center of this subnet.
  availability_zone = "us-east-2a"

  tags = {
    Name = "Private Subnet"
  }
}

# Creating an Internet Gateway for the VPC
resource "aws_internet_gateway" "Internet_Gateway" {
  depends_on = [
    aws_vpc.custom,
    aws_subnet.subnet1,
    aws_subnet.subnet2
  ]

  # VPC in which it has to be created!
  vpc_id = aws_vpc.custom.id

  tags = {
    Name = "IG-Public-&-Private-VPC"
  }
}

# Creating an Route Table for the public subnet!
resource "aws_route_table" "Public-Subnet-RT" {
  depends_on = [
    aws_vpc.custom,
    aws_internet_gateway.Internet_Gateway
  ]

  # VPC ID
  vpc_id = aws_vpc.custom.id

  # NAT Rule
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Internet_Gateway.id
  }

  tags = {
    Name = "Route Table for Internet Gateway"
  }
}

# Creating a resource for the Route Table Association!
resource "aws_route_table_association" "RT-IG-Association" {

  depends_on = [
    aws_vpc.custom,
    aws_subnet.subnet1,
    aws_subnet.subnet2,
    aws_route_table.Public-Subnet-RT
  ]

  # Public Subnet ID
  subnet_id = aws_subnet.subnet1.id

  #  Route Table ID
  route_table_id = aws_route_table.Public-Subnet-RT.id
}

# Creating a Security Group for Web Server
resource "aws_security_group" "WS-SG" {

  depends_on = [
    aws_vpc.custom,
    aws_subnet.subnet1,
    aws_subnet.subnet2
  ]

  description = "HTTP, PING, SSH"

  # Name of the security Group!
  name = "webserver-sg"

  # VPC ID in which Security group has to be created!
  vpc_id = aws_vpc.custom.id

  # Created an inbound rule for webserver
  ingress {
    description = "HTTP for webserver"
    from_port   = 80
    to_port     = 80

    # Here adding tcp instead of http, because http in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for ping
  ingress {
    description = "Ping"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22

    # Here adding tcp instead of ssh, because ssh in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outward Network Traffic for the WordPress
  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Creating security group for MySQL, this will allow access only from the instances having the security group created above.
resource "aws_security_group" "MySQL-SG" {

  depends_on = [
    aws_vpc.custom,
    aws_subnet.subnet1,
    aws_subnet.subnet2,
    aws_security_group.WS-SG
  ]

  description = "MySQL Access only from the Webserver Instances!"
  name        = "mysql-sg"
  vpc_id      = aws_vpc.custom.id

  # Created an inbound rule for MySQL
  ingress {
    description     = "MySQL Access"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.WS-SG.id]
  }

  egress {
    description = "output from MySQL"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating security group for Bastion Host
resource "aws_security_group" "BH-SG" {

  depends_on = [
    aws_vpc.custom,
    aws_subnet.subnet1,
    aws_subnet.subnet2
  ]

  description = "MySQL Access only from the Webserver Instances!"
  name        = "bastion-host-sg"
  vpc_id      = aws_vpc.custom.id

  # Created an inbound rule for Bastion Host SSH
  ingress {
    description = "Bastion Host SG"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from Bastion Host"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Creating security group for MySQL Bastion Host Access
resource "aws_security_group" "DB-SG-SSH" {

  depends_on = [
    aws_vpc.custom,
    aws_subnet.subnet1,
    aws_subnet.subnet2,
    aws_security_group.BH-SG
  ]

  description = "MySQL Bastion host access for updates!"
  name        = "mysql-sg-bastion-host"
  vpc_id      = aws_vpc.custom.id

  # Created an inbound rule for MySQL Bastion Host
  ingress {
    description     = "Bastion Host SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.BH-SG.id]
  }

  egress {
    description = "output from MySQL BH"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating an AWS instance for the Webserver!
resource "aws_instance" "webserver" {

  depends_on = [
    aws_vpc.custom,
    aws_subnet.subnet1,
    aws_subnet.subnet2,
    aws_security_group.BH-SG,
    aws_security_group.DB-SG-SSH
  ]

  # AMI ID [I have used my custom AMI which has some softwares pre installed]
  ami           = "ami-08962a4068733a2b6"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet1.id

  # Keyname and security group are obtained from the reference of their instances created above!
  # Here I am providing the name of the key which is already uploaded on the AWS console.
  key_name = "public"

  # Security groups to use!
  vpc_security_group_ids = [aws_security_group.WS-SG.id]

  tags = {
    Name = "Webserver_From_Terraform"
  }

  # Installing required softwares into the system!
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("/home/ubuntu/Downloads/public.pem")
    host        = aws_instance.webserver.public_ip
  }

  # Code for installing the softwares!
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install nginx -y"
    ]
  }
}

# Creating an AWS instance for the MySQL! It should be launched in the private subnet!
resource "aws_instance" "MySQL" {
  depends_on = [
    aws_instance.webserver,
  ]

  # Using my custom Private AMI which has most of the things configured for WordPress
  # i.e. MySQL Installed!
  ami           = "ami-08962a4068733a2b6"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet2.id

  # Keyname and security group are obtained from the reference of their instances created above!
  key_name = "public"

  # Attaching 2 security groups here, 1 for the MySQL Database access by the Web-servers,
  # & other one for the Bastion Host access for applying updates & patches!
  vpc_security_group_ids = [aws_security_group.MySQL-SG.id, aws_security_group.DB-SG-SSH.id]

  tags = {
    Name = "MySQL_From_Terraform"
  }
}

# Creating an AWS instance for the Bastion Host, It should be launched in the public Subnet!
resource "aws_instance" "Bastion-Host" {
  depends_on = [
    aws_instance.webserver,
    aws_instance.MySQL
  ]

  ami           = "ami-08962a4068733a2b6"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet1.id

  # Keyname and security group are obtained from the reference of their instances created above!
  key_name = "public"

  # Security group ID's
  vpc_security_group_ids = [aws_security_group.BH-SG.id]
  tags = {
    Name = "Bastion_Host"
  }
}
