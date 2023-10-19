# data "aws_availability_zones" "available_zones" {
#   state = "available"
# }

# #VPC Setting
# resource "aws_vpc" "default" {
#   cidr_block = var.cidr_block
# }

# resource "aws_subnet" "public" {
#   count                   = 2
#   cidr_block              = cidrsubnet(aws_vpc.default.cidr_block, 8, 2 + count.index)
#   availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
#   vpc_id                  = aws_vpc.default.id
#   map_public_ip_on_launch = true
# }

# resource "aws_subnet" "private" {
#   count             = 2
#   cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)
#   availability_zone = data.aws_availability_zones.available_zones.names[count.index]
#   vpc_id            = aws_vpc.default.id
# }

# resource "aws_internet_gateway" "gateway" {
#   vpc_id = aws_vpc.default.id
# }

# resource "aws_route" "internet_access" {
#   route_table_id         = aws_vpc.default.main_route_table_id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.gateway.id
# }

# resource "aws_eip" "gateway" {
#   count         = 2
#   domain        = "vpc"
#   depends_on    = [aws_internet_gateway.gateway]
# }

# resource "aws_nat_gateway" "gateway" {
#   count         = 2
#   subnet_id     = element(aws_subnet.public.*.id, count.index)
#   allocation_id = element(aws_eip.gateway.*.id, count.index)
# }

# resource "aws_route_table" "private" {
#   count  = 2
#   vpc_id = aws_vpc.default.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
#   }
# }

# resource "aws_route_table_association" "private" {
#   count          = 2
#   subnet_id      = element(aws_subnet.private.*.id, count.index)
#   route_table_id = element(aws_route_table.private.*.id, count.index)
# }

# # Security Group
# resource "aws_security_group" "lb" {
#   name   = "${var.app_name}-alb-sg"
#   vpc_id = aws_vpc.default.id

#   ingress {
#     protocol    = "tcp"
#     from_port   = 80
#     to_port     = 80
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# # ALB Setting
# resource "aws_lb" "default" {
#   name                  = "${var.app_name}-lb"
#   load_balancer_type    = var.load_balancer_type
#   internal              = var.internal
#   subnets               = aws_subnet.private.*.id
#   security_groups       = [aws_security_group.lb.id]
# }

# resource "aws_lb_target_group" "api" {
#   name        = "${var.app_name}-target-group"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = aws_vpc.default.id
#   target_type = "ip"

#   health_check {
#     path                = var.healthcheck_path
#     port                = var.healthcheck_port
#     protocol            = "HTTP"
#     healthy_threshold   = 5
#     unhealthy_threshold = 2
#     matcher             = var.healthcheck_code
#   }
# }

# resource "aws_lb_listener" "api" {
#   load_balancer_arn = aws_lb.default.id
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     target_group_arn = aws_lb_target_group.api.id
#     type             = "forward"
#   }
# }

# # ECR 
# resource "aws_ecr_repository" "this" {
#   name  = "${var.app_name}-app"
# }

# resource "aws_ecr_lifecycle_policy" "cleanup_policies" {

#   repository = aws_ecr_repository.this.name
#   policy     = <<EOF
#   {
#     "rules": [
#         {
#             "rulePriority": 1,
#             "description": "Expire untagged images older than 14 days",
#             "selection": {
#                 "tagStatus": "untagged",
#                 "countType": "sinceImagePushed",
#                 "countUnit": "days",
#                 "countNumber": 14
#             },
#             "action": {
#                 "type": "expire"
#             }
#         }
#     ]
#   }
#   EOF
# }

# # S3
# resource "aws_s3_bucket" "this" {
#   bucket = var.bucket_app_name
# }

# resource "aws_s3_bucket_acl" "this" {
#   bucket     = aws_s3_bucket.this.id
#   acl        = "public-read"
#   depends_on = [
#     aws_s3_bucket_ownership_controls.this,
#     aws_s3_bucket_public_access_block.this,
#   ]
# }

# resource "aws_s3_bucket_ownership_controls" "this" {
#   bucket = aws_s3_bucket.this.id

#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "this" {
#   bucket = aws_s3_bucket.this.id

#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }

# # ECS Setting
# data "aws_iam_policy_document" "ecs_tasks_execution_role" {
#   statement {
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["ecs-tasks.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "ecs_tasks_execution_role" {
#   name               = "ecs-task-execution-role"
#   assume_role_policy = "${data.aws_iam_policy_document.ecs_tasks_execution_role.json}"
# }

# resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role" {
#   role       = "${aws_iam_role.ecs_tasks_execution_role.name}"
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# resource "aws_ecs_task_definition" "main" {
#   family                   = "${var.app_name}-app"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = var.ecs_task_cpu
#   memory                   = var.ecs_task_mem
#   execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn

#   container_definitions = <<DEFINITION
# [
#   {
#     "image": "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.this.name}:${var.image_tag}",
#     "cpu": ${var.ecs_task_cpu},
#     "memory": ${var.ecs_task_mem},
#     "name": "${var.app_name}-app",
#     "networkMode": "awsvpc",
#     "portMappings": [
#       {
#         "containerPort": ${var.app_port},
#         "hostPort": ${var.app_port}
#       }
#     ]
#   }
# ]
# DEFINITION
# }

# resource "aws_security_group" "task" {
#   name   = "${var.app_name}-task-sg"
#   vpc_id = aws_vpc.default.id

#   ingress {
#     protocol        = "tcp"
#     from_port       = 4000
#     to_port         = 4000
#     security_groups = [aws_security_group.lb.id]
#   }

#   egress {
#     protocol    = "-1"
#     from_port   = 0
#     to_port     = 0
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_ecs_cluster" "main" {
#   name = "${var.app_name}-cluster"
# }

# resource "aws_ecs_service" "api" {
#   name            = "${var.app_name}-service"
#   cluster         = aws_ecs_cluster.main.id
#   task_definition = aws_ecs_task_definition.main.arn
#   desired_count   = var.desired_count
#   launch_type     = "FARGATE"

#   network_configuration {
#     security_groups = [aws_security_group.task.id]
#     subnets         = aws_subnet.private.*.id
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.api.id
#     container_name   = "${var.app_name}-app"
#     container_port   = var.app_port
#   }

#   depends_on = [aws_lb_listener.api]
# }

# resource "aws_appautoscaling_target" "api_app" {
#   max_capacity = var.max_capacity
#   min_capacity = var.min_capacity
#   resource_id = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
#   scalable_dimension = "ecs:service:DesiredCount"
#   service_namespace = "ecs"
# }

# resource "aws_appautoscaling_policy" "memory" {
#   name               = "tracking-memory"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.api_app.resource_id
#   scalable_dimension = aws_appautoscaling_target.api_app.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.api_app.service_namespace

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageMemoryUtilization"
#     }

#     target_value       = var.threshold_mem
#   }
# }

# resource "aws_appautoscaling_policy" "cpu" {
#   name = "tracking-cpu"
#   policy_type = "TargetTrackingScaling"
#   resource_id = aws_appautoscaling_target.api_app.resource_id
#   scalable_dimension = aws_appautoscaling_target.api_app.scalable_dimension
#   service_namespace = aws_appautoscaling_target.api_app.service_namespace

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }

#     target_value = var.threshold_cpu
#   }
# }

# # API Gateway
# #1: API Gateway
# resource "aws_apigatewayv2_api" "api" {
#   name          = "${var.app_name}-gateway"
#   protocol_type = "HTTP"
# }
# #2: VPC Link
# resource "aws_apigatewayv2_vpc_link" "vpc_link" {
#   name               = "${var.app_name}-vpclink"
#   security_group_ids = [aws_security_group.lb.id]
#   subnet_ids         = aws_subnet.private.*.id
# }
# #3: API Integration
# resource "aws_apigatewayv2_integration" "api_integration" {
#   api_id             = aws_apigatewayv2_api.api.id
#   integration_type   = "HTTP_PROXY"
#   connection_id      = aws_apigatewayv2_vpc_link.vpc_link.id
#   connection_type    = "VPC_LINK"
#   description        = "VPC integration"
#   integration_method = "ANY"
#   integration_uri    = aws_lb_listener.api.arn
#   depends_on         = [aws_lb.default]
# }
# #4: APIGW Route
# resource "aws_apigatewayv2_route" "default_route" {
#   api_id    = aws_apigatewayv2_api.api.id
#   route_key = "$default"
#   target    = "integrations/${aws_apigatewayv2_integration.api_integration.id}"
# }
# #5: APIGW Stage
# resource "aws_apigatewayv2_stage" "default_stage" {
#   api_id      = aws_apigatewayv2_api.api.id
#   name        = "$default"
#   auto_deploy = true
# }

# # Cloudfront
# resource "aws_cloudfront_distribution" "main_distribution" {
#   enabled                    = true

#   origin {
#     domain_name              = "${aws_apigatewayv2_api.api.id}.execute-api.${var.region}.amazonaws.com"
#     origin_id                = "API-GW-${aws_apigatewayv2_api.api.id}"
#     custom_origin_config {
#       http_port              = "80"
#       https_port             = "443"
#       origin_protocol_policy = "https-only"
#       origin_ssl_protocols   = ["TLSv1.2"]
#     }
#   }
#   default_cache_behavior {
#     allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = "API-GW-${aws_apigatewayv2_api.api.id}"
# #     cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized

#     forwarded_values {
#       query_string = true
#       cookies {
#         forward = "all"
#       }
#     }

#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#     compress               = true
#     viewer_protocol_policy = "redirect-to-https"
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }
#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }
# }