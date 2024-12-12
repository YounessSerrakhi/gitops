variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  default = ["10.0.3.0/24"]
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "Name of the EC2 key pair"
  default     = "serrakhi"
}

variable "db_username" {
  description = "MySQL database username"
  type        = string
}

variable "db_password" {
  description = "MySQL database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the MySQL database"
  type        = string
  default     = "myappdb"
}