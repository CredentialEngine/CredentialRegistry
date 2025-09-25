variable "secret_name" {
  description = "Name of the Secrets Manager secret (must be unique per region)."
  type        = string
}

variable "description" {
  description = "Description of the secret."
  type        = string
  default     = null
}

variable "secret_values" {
  description = "Map of key/value pairs that will be stored as JSON in the secret."
  type        = map(string)
}

variable "tags" {
  description = "Optional tags to attach to the secret."
  type        = map(string)
  default     = {}
}
