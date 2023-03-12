resource "aws_vpc" "tf_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "tf_subnet" {
  vpc_id                  = aws_vpc.tf_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public-subnet"
  }
}

resource "aws_internet_gateway" "tf_internet_gw" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "dev-internet-gw"
  }

}


resource "aws_route_table" "tf_routetable" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "dev-public-route-table"
  }
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table.tf_routetable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tf_internet_gw.id

}

resource "aws_route_table_association" "tf_public_assoc" {
  subnet_id      = aws_subnet.tf_subnet.id
  route_table_id = aws_route_table.tf_routetable.id
}

resource "aws_security_group" "tf_dev_sg" {
  name        = "dev-sg"
  description = "dev securty group terraform project"
  vpc_id      = aws_vpc.tf_vpc.id

  ingress {
    description      = "allow traffic from all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-sg"
  }
}
resource "aws_key_pair" "tf-auth" {
  key_name   = "tf-dev-key"
  public_key = file("~/.ssh/tfkey.pub")
}


resource "aws_instance" "tf-dev-ec2" {
  ami           = data.aws_ami.tf_server_ami.id
  instance_type = "t2.micro"
  key_name = aws_key_pair.tf-auth.id
  vpc_security_group_ids = [aws_security_group.tf_dev_sg.id]
  subnet_id = aws_subnet.tf_subnet.id
  user_data = file("userdata.tpl")
  

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "tf-dev-ec2"
  }
  

}

