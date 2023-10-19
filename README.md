# DevOps Challenge - Infrastructure

## **Architect**

Reference this document: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-private-integration.html![
Architectural overview of the API that you create in this tutorial. Clients use an API Gateway HTTP API to
access your Amazon ECS service through a VPC link.
](https://docs.aws.amazon.com/images/apigateway/latest/developerguide/images/private-integration.png)

* Create an IAM user and attach policy name `AdministratorAccess` to have permission create all resources
* Create a policy name `ecs-deploy-policy.yaml` and attach to IAM user for Github Actions has permission deploy ECS
* ```
  {
      "Version": "2012-10-17",
      "Statement": [{
      "Action":[
        "ecs:DescribeServices",
        "ecs:CreateTaskSet",
        "ecs:DeleteTaskSet",
        "ecs:ListClusters",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateServicePrimaryTaskSet",
        "ecs:UpdateService",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:ModifyRule",
        "lambda:InvokeFunction",
        "lambda:ListFunctions",
        "cloudwatch:DescribeAlarms",
        "sns:Publish",
        "sns:ListTopics", 
        "s3:GetObject",
        "s3:GetObjectVersion",
        "codedeploy:CreateApplication", 
        "codedeploy:CreateDeployment", 
        "codedeploy:CreateDeploymentGroup", 
        "codedeploy:GetApplication", 
        "codedeploy:GetDeployment", 
        "codedeploy:GetDeploymentGroup", 
        "codedeploy:ListApplications", 
        "codedeploy:ListDeploymentGroups", 
        "codedeploy:ListDeployments", 
        "codedeploy:StopDeployment", 
        "codedeploy:GetDeploymentTarget", 
        "codedeploy:ListDeploymentTargets", 
        "codedeploy:GetDeploymentConfig", 
        "codedeploy:GetApplicationRevision", 
        "codedeploy:RegisterApplicationRevision", 
        "codedeploy:BatchGetApplicationRevisions", 
        "codedeploy:BatchGetDeploymentGroups", 
        "codedeploy:BatchGetDeployments", 
        "codedeploy:BatchGetApplications", 
        "codedeploy:ListApplicationRevisions", 
        "codedeploy:ListDeploymentConfigs", 
        "codedeploy:ContinueDeployment"   
     ],
     "Resource":"*",
     "Effect":"Allow"
  },{"Action":[
        "iam:PassRole"
     ],
     "Effect":"Allow",
     "Resource":"*",
     "Condition":{"StringLike":{"iam:PassedToService":[
              "ecs-tasks.amazonaws.com",
              "codedeploy.amazonaws.com"
           ]
        }
     }
  }]
  }
  ```
* Use terraform for this IaC
* Backend is local for testing
* Change values into file `terraform.auto.tfvars` with your informationb. Create*
* Firstly, create resources: VPC, ALB, ECR, S3
* After have S3 and ECR repo, edit information into file `nodemon.json`, build code and push to this ECR repo
* Create ECS and API Gateway later
* Terraform output will give `api_gw_url` and use this link to test api application
