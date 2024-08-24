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

###########################
########### EC2 ###########
###########################

# Create an IAM instance profile for the EC2 instance
resource "aws_iam_instance_profile" "instance-profile" {
  name = "ec2-instance-profile"
  role = "LabRole"
}

resource "aws_instance" "rds-instance" {
  ami = "ami-03a4942b8fcc1f29d" # <https://cloud-images.ubuntu.com/locator/ec2/> 
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private-subnet[0].id
  associate_public_ip_address = true
  key_name                    = "vockey" # name from FIAP
  iam_instance_profile        = aws_iam_instance_profile.instance-profile.name

  vpc_security_group_ids = [
    aws_security_group.rds-security-group.id
  ]
  root_block_device {
    delete_on_termination = true
    # iops                  = 150 # only valid for volume_type io1
    volume_size = 50
    volume_type = "gp2"
  }
  tags = {
    Name = "instance-profile"
    OS   = "ubuntu"
  }

  depends_on = [aws_security_group.rds-security-group]

#   user_data = base64encode(templatefile("user_data.sh", {
#     DB_USER = aws_db_instance.mysql_8.username
#     DB_PASSWORD_PARAM = data.aws_ssm_parameter.db_password.name
#     DB_HOST = aws_db_instance.mysql_8.address
#     DB_PORT = aws_security_group_rule.allow_mysql_in.from_port
#     DB_NAME = aws_db_instance.mysql_8.db_name
#   }))
}