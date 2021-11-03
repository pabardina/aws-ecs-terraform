# ecs.tf

resource "aws_ecs_cluster" "main" {
  for_each = var.environments

  name = "app-cluster-${each.key}"
}

data "template_file" "app" {
  for_each = var.environments

  template = file("./templates/ecs/app_${each.key}.json.tpl")

  vars = {
    app_image      = var.app_image
    app_port       = var.app_port
    fargate_cpu    = var.fargate_cpu
    fargate_memory = var.fargate_memory
    aws_region     = var.aws_region
  }
}

resource "aws_ecs_task_definition" "app" {
  for_each = var.environments

  family                   = "app-task-${each.key}"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.app[each.key].rendered
}

resource "aws_ecs_service" "main" {
  for_each = var.environments

  name            = "app-service-${each.key}"
  cluster         = aws_ecs_cluster.main[each.key].id
  task_definition = aws_ecs_task_definition.app[each.key].arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app[each.key].id
    container_name   = "app-${each.key}"
    container_port   = var.app_port
  }

  depends_on = [aws_alb_listener.front_end, aws_iam_role_policy_attachment.ecs_task_execution_role]
}

