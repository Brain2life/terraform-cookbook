resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name              = var.db_name
  username             = data.sops_file.db_credentials.data["db_username"]
  password             = data.sops_file.db_credentials.data["db_password"]
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true

  # Optional: Define VPC security group IDs if needed
  # vpc_security_group_ids = [aws_security_group.db_sg.id]

  # Optional: Define DB subnet group if deploying into a VPC
  # subnet_ids = [aws_subnet.db_subnet.id]
}
