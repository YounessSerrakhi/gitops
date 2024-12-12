resource "aws_security_group" "mysql_sg" {
  name        = "serrakhiApp-mysql-sg"
  description = "Security group for serrakhiApp MySQL Server"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Consider restricting this in production
  }

  # MySQL access from VPC
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "serrakhiApp MySQL Security Group"
  }
}

resource "aws_instance" "mysql_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private[0].id  # Place in first private subnet
  
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  
  key_name = "serrakhi"

  user_data = base64encode(templatefile("scripts/mysql_setup.sh", {
    DB_NAME     = var.db_name,
    DB_USERNAME = var.db_username,
    DB_PASSWORD = var.db_password
  }))

  tags = {
    Name = "serrakhiApp MySQL Server"
  }
}