resource "aws_ecs_service" "app" {
  name            = "ephemeral-service-${var.branch_name}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = aws_subnet.public[*].id
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "app"
    container_port   = 80
  }

  tags = {
    ttl = "${var.ttl_hours}h"
    created_at = "${timestamp()}"
  }

  depends_on = [aws_lb_listener.app_listener]
}
