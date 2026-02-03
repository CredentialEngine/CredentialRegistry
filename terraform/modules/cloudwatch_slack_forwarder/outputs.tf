output "lambda_arn" {
  description = "ARN of the CloudWatch-to-Slack forwarder Lambda function"
  value       = aws_lambda_function.forwarder.arn
}

output "function_name" {
  description = "Name of the CloudWatch-to-Slack forwarder Lambda function"
  value       = aws_lambda_function.forwarder.function_name
}
