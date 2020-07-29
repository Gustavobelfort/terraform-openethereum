resource "aws_security_group" "lambda" {
  name        = "lambda-sg"
  description = "Security group for the lambda rpc monitoring"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS008
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS008
  }

  vpc_id = aws_vpc.default.id

  tags = {
    Provisioner    = "terraform"
    ProvisionerSrc = var.provisionersrc
    Application    = var.application
    Name           = "LambdaOpenEthereum"
  }
}

resource "aws_api_gateway_rest_api" "openethereum" {
  name        = "openethereum-monitoring"
  description = "Terraform Serverless OpenEthereum Monitoring"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.openethereum.id
  parent_id   = aws_api_gateway_rest_api.openethereum.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.openethereum.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.openethereum.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.openethereum.invoke_arn
}

resource "aws_lambda_function" "openethereum" {
  function_name = "openethereum-monitoring"

  s3_bucket = "ethereum-lambda-monitoring"
  s3_key    = "openethereum.zip"
  handler   = "main.handler"
  runtime   = "nodejs12.x"

  role = aws_iam_role.lambda_exec.arn

  vpc_config {
    subnet_ids         = [aws_subnet.us-east-1a-public.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      RPC_ENDPOINT = "${aws_instance.ethereum[0].private_ip}:8545"
    }
  }
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.openethereum.id
  resource_id   = aws_api_gateway_rest_api.openethereum.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_deployment" "openethereum" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.openethereum.id
  stage_name  = "prod"
}




resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.openethereum.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.openethereum.invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.openethereum.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.openethereum.execution_arn}/*/*"
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_openethereum_lambda"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

}

resource "aws_iam_policy" "vpc-policy" {
  name        = "lambda-vpc"
  description = "VPC Permissions for the aws lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "vpc-policy-attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.vpc-policy.arn
}
