provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MyVPC"
  }
}

# Sub-redes
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-2b"
  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "PrivateSubnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MainInternetGateway"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route" "public_to_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "MyNATGateway"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "PrivateRouteTable"
  }
}

resource "aws_route" "private_to_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "development" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # Seu IP público
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevelopmentSecurityGroup"
  }
}

resource "aws_security_group" "database" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.development.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DatabaseSecurityGroup"
  }
}

# EC2 Instances
resource "aws_instance" "development" {
  ami           = "ami-00eb69d236edcfaf8"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.development.id]
  key_name      = "dev-keypair"

  tags = {
    Name = "DevelopmentInstance"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install python3-pip -y
              pip install fastapi uvicorn
              echo "from fastapi import FastAPI" > app.py
              echo "app = FastAPI()" >> app.py
              echo "@app.get('/')" >> app.py
              echo "def read_root():" >> app.py
              echo "    return {'Hello': 'World'}" >> app.py
              nohup uvicorn app:app --host 0.0.0.0 --port 8000 &
            EOF

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install python3-pip -y",
      "pip3 install fastapi uvicorn",
      "echo 'from fastapi import FastAPI\napp = FastAPI()\n@app.get('/')\ndef read_root():\n    return {\"Hello\": \"World\"}' > app.py",
      "nohup uvicorn app:app --host 0.0.0.0 --port 8000 &",

      # Instala o Zabbix Agent
      "sudo apt update",
      "sudo apt install -y zabbix-agent",

      # Configura o Zabbix Agent para conexão ativa
      "sudo sed -i 's/^Server=127.0.0.1/Server=3.142.31.126/' /etc/zabbix/zabbix_agentd.conf",
      "sudo sed -i 's/^ServerActive=127.0.0.1/ServerActive=3.142.31.126/' /etc/zabbix/zabbix_agentd.conf",
      "sudo sed -i 's/^Hostname=Zabbix server/Hostname=Development/' /etc/zabbix/zabbix_agentd.conf",

      # Reinicia o agente para aplicar as configurações
      "sudo systemctl restart zabbix-agent",
      "sudo systemctl enable zabbix-agent"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu" # Replace with your user
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
}

resource "aws_instance" "database" {
  ami           = "ami-00eb69d236edcfaf8"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.database.id]
  key_name      = "dev-keypair"

  tags = {
    Name = "DatabaseInstance"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install mysql-server -y
              systemctl start mysql
              systemctl enable mysql
            EOF

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install mysql-server -y",
      "sudo systemctl start mysql",
      "sudo mysql -e \"CREATE USER 'admin'@'%' IDENTIFIED BY 'yourpassword';\"",
      "sudo mysql -e \"GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';\"",
      "sudo mysql -e \"FLUSH PRIVILEGES;\"",

      # Instala o Zabbix Agent
      "sudo apt update",
      "sudo apt install -y zabbix-agent",

      # Configura o Zabbix Agent para conexão ativa
      "sudo sed -i 's/^Server=127.0.0.1/Server=<ZABBIX_SERVER_IP>/' /etc/zabbix/zabbix_agentd.conf",
      "sudo sed -i 's/^ServerActive=127.0.0.1/ServerActive=<ZABBIX_SERVER_IP>/' /etc/zabbix/zabbix_agentd.conf",
      "sudo sed -i 's/^Hostname=Zabbix server/Hostname=${self.tags.Name}/' /etc/zabbix/zabbix_agentd.conf",

      # Reinicia o agente para aplicar as configurações
      "sudo systemctl restart zabbix-agent",
      "sudo systemctl enable zabbix-agent"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
}

resource "aws_instance" "zabbix_server" {
  ami           = "ami-00d5c4dd05b5467c4"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.zabbix.id]
  key_name      = "dev-keypair"

  tags = {
    Name = "ZabbixServer"
  }
}

resource "aws_security_group" "zabbix" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10051
    to_port     = 10051
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ZabbixSecurityGroup"
  }
}

