# Vpc
account_id = ""
region = "ap-southeast-1"
cidr_block = "10.1.0.0/16"

# App
app_name = "api"

# Load Balancer
load_balancer_type = "application"
internal    = "true"
healthcheck_path = "/ping"
healthcheck_port = "traffic-port"
healthcheck_code = "200"

# S3
bucket_app_name = ""

# ECS
ecs_task_cpu = 1024
ecs_task_mem = 2048
image_tag = "latest"
app_port = 4000

desired_count = 2
max_capacity = 5
min_capacity = 2

threshold_mem = 80
threshold_cpu = 80