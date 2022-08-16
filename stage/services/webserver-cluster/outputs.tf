
    output "public_ip" {
      value = aws_instance.warmup.public_ip
      description = "The public IP address of the web server"
    }

    output "alb_dns_name" {
        value = aws_lb.warmup-asg.dns_name
        description = "The domain name of the load balancer"
    }