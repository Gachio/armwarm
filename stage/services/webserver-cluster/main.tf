    
        provider "aws" {
        region = "us-east-2"
    }

# Auto Scaling Group 

    resource "aws_launch_configuration" "warmup-asg" {
      image_id = "ami-0c55b159cbfafe1f0"
      instance_type = "t2.micro"
      security_groups = [aws_security_group.instance.id]
      user_data = data.template_file.user_data.rendered
      
        data "template_file" "user-data" {
            template = file("user-data.sh")
            vars = {
                server_port = var.server_port
                db_address = data.terraform_remote_state.db.outputs.address
                db_port = data.terraform_remote_state.db.outputs.port
            }
        }

    # Required when using a launch configuration with an auto scaling group.
    # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html

        lifecycle {
            create_before_destroy = true
        }
    }

    resource "aws_autoscaling_group" "warmup-asg" {
      launch_configuration = aws_launch_configuration.warmup-asg.name
      vpc_zone_identifier = data.aws_subnets.default.ids

      target_group_arns = [aws_lb_target_group.asg.arn]
      health_check_type = "ELB"

      min_size = 2
      max_size = 10

        tag {
            key = "Name"
            value = "terraform-asg-warmup-asg"
            propagate_at_launch = true
        }
    }

    resource "aws_security_group" "instance" {
        name = "terraform-warmup-instance"

        ingress {
            from_port = var.server_port
            to_port = var.server_port
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
  
    }

    resource "aws_lb" "warmup-asg" {
        name = "terraform-asg-warmup-asg"
        load_balancer_type = "application"
        subnets = data.aws_subnets.default.ids
        security_groups = [aws_security_group.alb.id]
    }

    resource "aws_lb_listener" "http" {
        load_balancer_arn = aws_lb.warmup-asg.arn
        port = 80
        protocol = "HTTP"

    # By default, return a simple 404 page
        default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
            }
        }     
    }

    resource "aws_lb_target_group" "asg" {
        name = "terraform-asg-warmup-asg"
        port = var.server_port
        protocol = "HTTP"
        vpc_id = data.aws_vpc.default.id

        health_check {
          path = "/"
          protocol = "HTTP"
          matcher = "200"
          interval = 15
          timeout = 3
          healthy_threshold = 2
          unhealthy_threshold = 2
        }
    }

    resource "aws_lb_listener_rule" "static" {
        listener_arn = aws_lb_listener.http.arn
        priority = 100
      
            condition {
                path_pattern {
                values = ["/static/*"] 
                }
            }   
            action {
            type = "forward"
            target_group_arn = aws_lb_target_group.asg.arn
            }
    }

    resource "aws_security_group" "alb" {
      name = "terraform-warmup-asg-alb"

    # Allow inbound HTTP requests
        ingress {
            from_port = 80
            to_port = 80
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }  

    # Allow all outbound requests
        egress {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    data "terraform_remote_state" "db" {
    backend = "s3"
        config = {
            bucket = "warmup-running-state"
            key    = "stage/data-store/mysql/terraform.tfstate"
            region = "us-east-2"
        }
    }

    data "aws_vpc" "default" {
        default = true
    }
    data "aws_subnets" "default" {
        filter {
            name   = "vpc-id"
            values = [data.aws_vpc.default.id]
        }
    }
