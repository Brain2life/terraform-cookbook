data "aws_secretsmanager_random_password" "rds_password" {
  password_length     = 20
  exclude_numbers     = false
  exclude_punctuation = true
  include_space       = false
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name = "my-org/my-env/my-rds-secret"
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    db_name  = var.rds_db_name
    username = var.rds_username,
    password = data.aws_secretsmanager_random_password.rds_password.random_password
  })
}

data "aws_secretsmanager_secret" "rds_secret" {
  name = aws_secretsmanager_secret.rds_secret.name
}

data "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = data.aws_secretsmanager_secret.rds_secret.id
}

# Define local variable with retrieved secrets
locals {
  rds_credentials = sensitive(jsondecode(data.aws_secretsmanager_secret_version.rds_secret_version.secret_string))
}

# Create Security Group for the RDS Database
resource "aws_security_group" "rds_sg" {
  name   = "rds-db-sg"
  vpc_id = data.aws_vpc.default.id

  # Allow MySQL traffic from Bastion Host's SG
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Outbound traffic (allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS Security Group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0.32"
  instance_class         = "db.t3.micro"
  vpc_security_group_ids = [aws_security_group.rds_sg.id] # Attach RDS SG

  db_name  = local.rds_credentials["db_name"]
  username = local.rds_credentials["username"]
  password = local.rds_credentials["password"]

  skip_final_snapshot = true
  publicly_accessible = false
  apply_immediately = true
}
