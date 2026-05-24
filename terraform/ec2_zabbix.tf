resource "aws_key_pair" "deployer" {
  key_name   = "diplom-deployer-key"
  public_key = file("~/.ssh/diplom_aws_key.pub")
}

resource "aws_security_group" "zabbix" {
  name        = "zabbix-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

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
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "zabbix_server" {
  ami                         = "ami-067bcf851477ebb78" 
  instance_type               = "t3.small" 
  subnet_id                   = module.vpc.public_subnets[0] 
  vpc_security_group_ids      = [aws_security_group.zabbix.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true  

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  } 

  tags = { Name = "Zabbix-Server" }
}

output "zabbix_server_public_ip" { value = aws_instance.zabbix_server.public_ip }
output "zabbix_server_private_ip" { value = aws_instance.zabbix_server.private_ip }

