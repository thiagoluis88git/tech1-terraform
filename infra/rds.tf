resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.private-subnet[*].id

  tags = {
    Name = "RDS Subnet Group"
  }
}

resource "aws_db_parameter_group" "rds-parameter-group" {
  name   = var.rds_config.name
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "fastfood-database" {
  identifier             = var.rds_config.name
  instance_class         = var.rds_config.instance_class
  allocated_storage      = var.rds_config.allocated_storage
  engine                 = var.rds_config.engine
  engine_version         = var.rds_config.engine_version
  username               = var.rds_config.username
  password               = var.db_password
  port                   = var.rds_config.port
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.name
  vpc_security_group_ids = [aws_security_group.rds-security-group.id]
  parameter_group_name   = aws_db_parameter_group.rds-parameter-group.name
  publicly_accessible    = false
  skip_final_snapshot    = true
}

resource "aws_security_group" "rds-security-group" {
  name        = "rds-security-group"
  description = "Allow inbound only via privates subnets traffic"
  vpc_id      = aws_vpc.fiap-vpc.id

  ingress {
    from_port       = 0
    to_port         = var.rds_config.port
    protocol        = "tcp"
    cidr_blocks     = var.networking.private_subnets  
  }

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = var.networking.private_subnets
  }

  tags = {
    Name        = "rds-security-group"
  }
}