provider "aws" {
  region = "sa-east-1"
}

resource "aws_internet_gateway" "igtw-proxy-subnet-1" {
	vpc_id = aws_vpc.proxy-vpc.id
}

resource "aws_route_table" "default_rt" {
	vpc_id = aws_vpc.proxy-vpc.id
	
	# default route to outter internet (gateway)
	route{
		cidr_block = "0.0.0.0/0" #default route
		gateway_id = aws_internet_gateway.igtw-proxy-subnet-1.id
	}

	# route to another (web servers) subnet is created by aws automatically
	# route{
		# cidr_block = "192.168.0.16/28"
		# gateway_id = "local"
	#}
}

resource "aws_route_table_association" "proxy-subnet-association" {
	subnet_id = aws_subnet.proxy-subnet-2.id
	route_table_id = aws_route_table.default_rt.id
}

resource "aws_vpc" "proxy-vpc" {
	cidr_block = "192.168.0.0/24"
}

resource "aws_subnet" "proxy-subnet-1" {
	vpc_id = aws_vpc.proxy-vpc.id
	cidr_block = "192.168.0.0/28" # (192.168.0.0 - 192.168.0.15) (web-servers)
	availability_zone = "sa-east-1a"
}

resource "aws_subnet" "proxy-subnet-2" {
	vpc_id = aws_vpc.proxy-vpc.id
	cidr_block = "192.168.0.16/28" # (192.168.0.16 - 192.168.0.31) (proxy-server)
	availability_zone = "sa-east-1a"
}

resource "aws_security_group" "proxy-sg" {
	name = "proxy-sg"
	description = "Allow SSH from my IP only & allow HTTP from anywhere"
	vpc_id = aws_vpc.proxy-vpc.id	

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]	
	}

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = [var.my_ip]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["0.0.0.0/0"] # My vpc subnet, improve = restrict it to web server ips only
	}
}

resource "aws_security_group" "web-servers-sg" {
	name = "web-server-sg"
	description = "Allow SSH from my IP only & allow HTTP from proxy only"
	vpc_id = aws_vpc.proxy-vpc.id	

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		security_groups = [aws_security_group.proxy-sg.id]	
	}

	ingress {

		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = [var.my_ip]
		security_groups = [aws_security_group.proxy-sg.id]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["${aws_instance.proxy-server.private_ip}/32"]
		security_groups = [aws_security_group.proxy-sg.id]
	}
}

resource "aws_instance" "proxy-server" {
	ami = "ami-0d866da98d63e2b42"
	instance_type = "t2.micro"
	subnet_id = aws_subnet.proxy-subnet-2.id
	vpc_security_group_ids = [aws_security_group.proxy-sg.id]

	key_name = "meu-par-de-chaves"
}

resource "aws_instance" "web-server" {
	count = 3
	ami = "ami-0d866da98d63e2b42"
	instance_type = "t2.micro"
	subnet_id = aws_subnet.proxy-subnet-1.id
	vpc_security_group_ids = [aws_security_group.web-servers-sg.id]

	key_name = "meu-par-de-chaves"
}



resource "aws_eip" "proxy-eip" {
        instance = aws_instance.proxy-server.id
}

