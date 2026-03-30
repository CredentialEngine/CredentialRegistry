output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "S3 bucket name for DB dumps"
}

output "bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "S3 bucket ARN for DB dumps"
}
