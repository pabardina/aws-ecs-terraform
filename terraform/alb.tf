# alb.tf

resource "aws_alb" "main" {
  for_each = var.environments

  name            = "app-load-balancer-${each.key}"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_alb_target_group" "app" {
  for_each = var.environments
  name        = "app-target-group-${each.key}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  for_each = var.environments

  load_balancer_arn = aws_alb.main[each.key].id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app[each.key].id
    type             = "forward"
  }
}

# only for prod
resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.main["prod"].id
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.alb_tls_cert_arn

  default_action {
    target_group_arn = aws_alb_target_group.app["prod"].id
    type             = "forward"
  }
}
