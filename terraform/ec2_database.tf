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

# Автоматическая генерация secret.yaml со свежими Base64-данными
resource "local_file" "k8s_secret" {
  content = templatefile("${path.module}/../k8s/secret.yaml.tpl", {
    # Считываем приватный IP инстанции и кодируем в Base64 на лету
    db_host_base64     = base64encode(aws_instance.app_database.private_ip)
    db_user_base64     = base64encode("db_user")
    db_password_base64 = base64encode("db_secure_password")
    db_name_base64     = base64encode("fs_support_db")
  })
  
  filename = "${path.module}/../k8s/secret.yaml"
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../ansible/inventory.ini.tpl", {
    zabbix_public_ip     = aws_instance.zabbix_server.public_ip
    zabbix_private_ip    = aws_instance.zabbix_server.private_ip
    database_primary_ip  = aws_instance.app_database.private_ip
    database_replica_ip  = aws_instance.app_database_replica.private_ip
  })
  filename = "${path.module}/../ansible/inventory.ini"
}

resource "aws_instance" "app_database_replica" {
  ami                    = "ami-067bcf851477ebb78"
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.database.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = { Name = "App-Database-Replica" }
}