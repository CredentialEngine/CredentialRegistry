data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  function_name = "${var.project_name}-cw-slack-forwarder"
  ssm_param     = "/${var.project_name}/slack/webhook-url"

  # Build a map keyed by filter name for use with for_each
  filter_map = { for f in var.log_filters : f.name => f }

  # Unique log group names that need Lambda invoke permission
  log_group_names = distinct([for f in var.log_filters : f.log_group_name])
}

# --- SSM Parameter for Slack Webhook URL ---

resource "aws_ssm_parameter" "slack_webhook" {
  name        = local.ssm_param
  description = "Slack incoming webhook URL for CloudWatch log forwarding"
  type        = "SecureString"
  value       = var.slack_webhook_url

  tags = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

# --- IAM Role for Lambda ---

resource "aws_iam_role" "lambda" {
  name = "${local.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "lambda" {
  name = "${local.function_name}-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      },
      {
        Sid    = "SSMRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
        ]
        Resource = aws_ssm_parameter.slack_webhook.arn
      },
    ]
  })
}

# --- Lambda Function ---

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/forwarder.py"
  output_path = "${path.module}/lambda/forwarder.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 14
  tags              = var.common_tags
}

resource "aws_lambda_function" "forwarder" {
  function_name    = local.function_name
  role             = aws_iam_role.lambda.arn
  handler          = "forwarder.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      SSM_WEBHOOK_PARAM = local.ssm_param
      SLACK_CHANNEL     = var.slack_channel
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda,
  ]

  tags = var.common_tags
}

# --- CloudWatch Log Subscription Filters ---

resource "aws_cloudwatch_log_subscription_filter" "this" {
  for_each = local.filter_map

  name            = each.key
  log_group_name  = each.value.log_group_name
  filter_pattern  = each.value.filter_pattern
  destination_arn = aws_lambda_function.forwarder.arn

  depends_on = [aws_lambda_permission.allow_cloudwatch]
}

# --- Lambda Permissions (one per unique log group) ---

resource "aws_lambda_permission" "allow_cloudwatch" {
  for_each = toset(local.log_group_names)

  statement_id  = "AllowCWLogs-${md5(each.value)}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.forwarder.function_name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${each.value}:*"
}
