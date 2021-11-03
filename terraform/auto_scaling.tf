# auto_scaling.tf

resource "aws_appautoscaling_target" "target" {
  for_each = var.environments

  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main[each.key].name}/${aws_ecs_service.main[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 6
}

# Automatically scale capacity up by one
resource "aws_appautoscaling_policy" "up" {
  for_each = var.environments

  name               = "app_scale_up-${each.key}"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main[each.key].name}/${aws_ecs_service.main[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

# Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "down" {
  for_each = var.environments

  name               = "app_scale_down-${each.key}"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main[each.key].name}/${aws_ecs_service.main[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

# CloudWatch alarm that triggers the autoscaling up policy
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  for_each = var.environments

  alarm_name          = "app_cpu_utilization_high-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"

  dimensions = {
    ClusterName = aws_ecs_cluster.main[each.key].name
    ServiceName = aws_ecs_service.main[each.key].name
  }

  alarm_actions = [
    aws_appautoscaling_policy.up[each.key].arn,
    aws_sns_topic.alarm[each.key].arn
  ]
}

# CloudWatch alarm that triggers the autoscaling down policy
resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  for_each = var.environments

  alarm_name          = "app_cpu_utilization_low-${each.key}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    ClusterName = aws_ecs_cluster.main[each.key].name
    ServiceName = aws_ecs_service.main[each.key].name
  }

  alarm_actions = [
    aws_appautoscaling_policy.down[each.key].arn,
  ]
}

resource "aws_sns_topic" "alarm" {
  for_each = var.environments

  name              = "alarm-cpu-${each.key}"
  delivery_policy   = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
  ## This local exec, suscribes your email to the topic 
  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.alarm_email} --region ${var.aws_region}"
  }
}
