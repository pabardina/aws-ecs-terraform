# logs.tf

# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "app_log_group" {
  for_each = var.environments

  name              = "/ecs/app-${each.value}"
  retention_in_days = 3

}

resource "aws_cloudwatch_log_stream" "app_log_stream" {
  for_each = var.environments

  name           = "app-log-stream"
  log_group_name = aws_cloudwatch_log_group.app_log_group[each.value].name
}

