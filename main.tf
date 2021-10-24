
# Create VPC
resource "aws_vpc" "WebServer_VPC" {
  cidr_block = var.cidr_block

  tags = {
    Name = "WebServer_VPC"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "webserver_gw" {
  vpc_id = aws_vpc.WebServer_VPC.id
}

# Create Routing table
resource "aws_route_table" "Public_Webserver_route_table" {
  vpc_id = aws_vpc.WebServer_VPC.id
  /*
  route = [
    {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.webserver_gw.id
    }
  ]*/

  tags = {
    Name = "Public_Webserver_route_table"
  }
}

# Create Subnet
resource "aws_subnet" "WebServer_subnets" {
  vpc_id            = aws_vpc.WebServer_VPC.id
  count             = var.my_count
  cidr_block        = var.public_cidrs[count.index]
  availability_zone = var.Availability_zone[count.index]

  tags = {
    Name = "WebServer_subnet-${count.index + 1}"
  }
}

# Create route_table_association to connect Routing table with Subnet
resource "aws_route_table_association" "WebServer_route_table_association" {
  count          = var.my_count
  subnet_id      = aws_subnet.WebServer_subnets.*.id[count.index]
  route_table_id = aws_route_table.Public_Webserver_route_table.id
}

# Create security Group

resource "aws_security_group" "Allow_Webserver_sg" {
  name        = "Webserver_sg"
  description = "Allow Webserver traffic"
  vpc_id      = aws_vpc.WebServer_VPC.id

  tags = {
    Name = "allow_webserver_traffic"
  }
}

# Ingress Security Port 80

resource "aws_security_group_rule" "http_inbound_access" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.Allow_Webserver_sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Ingress Security Port 22

resource "aws_security_group_rule" "ssh_inbound_access" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.Allow_Webserver_sg.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# All OutBound Access
resource "aws_security_group_rule" "all_outbound_access" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.Allow_Webserver_sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Create AWS Key Pair resource
resource "aws_key_pair" "my_webserver_instances_key" {
  key_name   = "my_webserver_instances_key"
  public_key = file(var.my_public_key)
}

# Create EC2 instances

resource "aws_instance" "Apache_EC2" {
  count                     = var.my_count
  ami                       = lookup(var.ami,var.region)
  instance_type             = var.instance_type
  availability_zone         = "${var.Availability_zone[count.index]}"
  key_name                  = aws_key_pair.my_webserver_instances_key.id
  subnet_id                 = aws_subnet.WebServer_subnets.*.id[count.index]
  vpc_security_group_ids    = [aws_security_group.Allow_Webserver_sg.id]
  user_data                 = file("install_apache.sh")
}

# Create a load balancer target group

resource "aws_lb_target_group" "webserver_lb_target_group" {

    health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name                   = "webserver-lb-target-group"
  port                   = 80
  protocol               = "HTTP"
  target_type     = "instance"
  vpc_id                 = aws_vpc.WebServer_VPC.id
}

# Attach Target group to the 2 EC2 instances

resource "aws_lb_target_group_attachment" "webserver_alb_target_group_attachment" {
  count            = var.my_count
  target_group_arn = "${aws_lb_target_group.webserver_lb_target_group.arn}"
  target_id        = "${element(aws_instance.Apache_EC2.*.id, count.index )}"
  port             = 80
}

/*
resource "aws_lb_target_group_attachment" "webserver_alb_target_group_attachment2" {
  count            = var.my_count
  target_group_arn = "${aws_lb_target_group.webserver_lb_target_group.arn}"
  target_id        = aws_instance.Apache_EC2[1].id
  port             = 80
}
*/

# Create application Load Balancer

resource "aws_lb" "webserver_alb" {
  name     = "webserver-alb"
  internal = false

  security_groups = [
    aws_security_group.Allow_Webserver_sg.id,
  ]

  subnets = [
    "${element(aws_subnet.WebServer_subnets.*.id, 0)}",
    "${element(aws_subnet.WebServer_subnets.*.id, 1)}"
  ]

  tags = {
    Name = "webserver-alb"
  }

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

# Create a load balancer listener

resource "aws_lb_listener" "webserver_alb_listner" {
  load_balancer_arn = "${aws_lb.webserver_alb.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.webserver_lb_target_group.arn}"
  }
} 