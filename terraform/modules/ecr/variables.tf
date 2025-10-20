variable "env" {
  description = "Environment (dev/stage/prod)"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "common_tags" {
  type = map(string)
  default = {
    "name" = "default value"
  }
}
