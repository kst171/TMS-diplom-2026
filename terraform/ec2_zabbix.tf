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
  ami                         = "ami-067bcf851477ebb78" # Ubuntu 24.04 LTS
  instance_type               = "t3.micro"               
  subnet_id                   = module.vpc.public_subnets[0] # Исправлен выбор элемента массива
  vpc_security_group_ids      = [aws_security_group.zabbix.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true 

  tags = { Name = "Zabbix-Server" }
}

output "zabbix_server_public_ip" { value = aws_instance.zabbix_server.public_ip }
output "zabbix_server_private_ip" { value = aws_instance.zabbix_server.private_ip }
