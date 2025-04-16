variable "branch_name" {
  description = "Git branch name"
  type        = string
}

variable "image_url" {
  description = "Docker image URI"
  type        = string
}

variable "ttl_hours" {
  description = "Time to live for this environment in hours"
  type        = number
  default     = 24
}
