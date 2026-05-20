resource "aws_security_group" "database" {
  name        = "app-database-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  ingress {
    from_port   = 10050
    to_port     = 10050
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

resource "aws_instance" "app_database" {
  ami                    = "ami-067bcf851477ebb78" 
  instance_type          = "t3.micro" 
  subnet_id              = module.vpc.private_subnets[0] # Развертывание в приватной сети
  vpc_security_group_ids = [aws_security_group.database.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = { Name = "App-Database" }
}

output "database_private_ip" { value = aws_instance.app_database.private_ip }
