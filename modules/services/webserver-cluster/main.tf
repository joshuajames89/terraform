/*Establish provider and default region. 
Ideally region will be defined by variable, keeping simple to prevent need to query ami id per-region in initial config 
*/

# Define local variables
locals {
  http_port = 80
  any_port = 0
  any_proto = "-1"
  tcp_proto = "tcp"
  all_ipv4 = ["0.0.0.0/0"]
}

# Fetch remote datasource to reference state data in instance user_data
data "terraform_remote_state" "mysql_db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key = var.db_remote_state_key
    region = "us-east-2"
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address = data.terraform_remote_state.mysql_db.outputs.address
    db_port = data.terraform_remote_state.mysql_db.outputs.port
  }
}

#Define 'main' VPC to avoid use of default
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}

#Establish IGW in main VPC to allow comms via public internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}

# Create private subnets within main VPC 
resource "aws_subnet" "private_us_east_2a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = "us-east-2a"

  tags = {
    "Name" = "private-us-east-2a"
  }
}

resource "aws_subnet" "private_us_east_2b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = "us-east-2b"

  tags = {
    "Name" = "private-us-east-2b"
  }
}
# END create private subnets

# Create public subnets within main VPC
resource "aws_subnet" "public_us_east_2a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "public-us-east-2a"
  }
}

resource "aws_subnet" "public_us_east_2b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "public-us-east-2b"
  }
}
# END create public subnets

# Define elastic IP for NAT translation in route
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat"
  }
}

#Create private route table and associate with nat gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private"
  }
}

# Create simple public route table, associate with internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public"
  }
}

# BEGIN associate route with private subnets
resource "aws_route_table_association" "private_us_east_2a" {
  subnet_id      = aws_subnet.private_us_east_2a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_us_east_2b" {
  subnet_id      = aws_subnet.private_us_east_2b.id
  route_table_id = aws_route_table.private.id
}
# END associate route with private subnets

# BEGIN associate route with public subnets
resource "aws_route_table_association" "public_us_east_1a" {
  subnet_id      = aws_subnet.public_us_east_2a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_us_east_2b" {
  subnet_id      = aws_subnet.public_us_east_2b.id
  route_table_id = aws_route_table.public.id
}
# END associate route with public subnets

# Create NAT gateway, associate with elastic IP and public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_us_east_2a.id

  tags = {
    Name = "nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Establish launch configuration for autoscaling group
resource "aws_launch_configuration" "example" {
    image_id = "ami-024e6efaf93d85776"
    instance_type = var.instance_type
    security_groups = [aws_security_group.instance.id]
    user_data = data.template_file.user_data.rendered

# Ensure new autoscale group has replacement resource and updated references PRIOR to destroying previous launch config.
# https://www.terraform.io/docs/providers/aws/r/launch_configuration.html

lifecycle {
  create_before_destroy = true
}
}

# Establish autoscaling group, utilize launch configuration, place within public subnets
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = [aws_subnet.public_us_east_2a.id, aws_subnet.public_us_east_2b.id]

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key = "Name"
    value = "${var.cluster_name}-asg"
    propagate_at_launch = true
  }
}

# Allow TCP:8080 ingress
resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "webappalb" {
  name = "${var.cluster_name}-lb"
  load_balancer_type = "application"
  subnets = [aws_subnet.public_us_east_2a.id, aws_subnet.public_us_east_2b.id]
  security_groups = [aws_security_group.alb.id]
}

# Configure load balancer, listen on http:80
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.webappalb.arn
  port = local.http_port
  protocol = "HTTP"

  # Default return 404 page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
  vpc_id = aws_vpc.main.id

  #Allow inbound HTTP
  ingress {
    from_port = local.http_port
    to_port = local.http_port
    protocol = local.tcp_proto
    cidr_blocks = local.all_ipv4
  }

  #Allow outbound requests
  egress {
    from_port = local.any_port
    to_port = local.any_port
    protocol = local.any_proto
    cidr_blocks = local.all_ipv4
  }
}

# Configure target server group for load balancer, implement health check
resource "aws_lb_target_group" "asg" {
  name = "${var.cluster_name}-lb-tg"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id

  health_check {
    path = "/index.html"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

terraform {
  backend "s3" {
    bucket = "terraform-state-mgmt-joshprom2000369" # update to use tfvars to create name w/ string concatenation
    key = "dev/services/frontend-services/webserver-cluster/terraform.tfstate"
    region = "us-east-2"
  }
}
