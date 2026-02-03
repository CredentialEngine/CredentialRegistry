variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL (stored in SSM as SecureString)"
  type        = string
  sensitive   = true
}

variable "slack_channel" {
  description = "Slack channel to post messages to (e.g. #alerts)"
  type        = string
}

variable "log_filters" {
  description = "List of CloudWatch log subscription filters to create"
  type = list(object({
    name           = string
    log_group_name = string
    filter_pattern = string
  }))
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
