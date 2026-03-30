variable "bucket_name" {
  description = "Name of the S3 bucket for DB dumps"
  type        = string
}

variable "expiration_days" {
  description = "Number of days after which dump objects are automatically deleted"
  type        = number
  default     = 7
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}
