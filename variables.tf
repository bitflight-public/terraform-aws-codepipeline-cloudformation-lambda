data "aws_caller_identity" "default" {}

data "aws_region" "default" {}

#Github Variables
variable "gh_owner" {
  default = ""
}

variable "gh_repo" {
  default = ""
}

variable "gh_branch" {
  default = ""
}

variable "gh_token" {
  default = ""
}

# Deployment details
variable "cluster_name" {
  default = "NONE"
}

variable "service_name" {
  default = "NONE"
}

variable "family_name" {
  default = "NONE"
}

variable "action_mode" {
  default = "NONE"
}

variable "stack_name" {
  default = "NONE"
}

variable "capabilities" {
  default = "NONE"
}

variable "output_file_name" {
  default = ""
}

variable "template_path" {
  default = ""
}

variable "cf_role_arn" {
  default = ""
}

variable "codebuild_project_name" {}
variable "codebuild_role_arn" {}

variable "deploy_type" {
  description = "Can be ECS or LAMBDA"
}

variable "tags" {
  default = {}
}

variable "namespace" {
  default = "global"
}

variable "name" {
  description = "The project name"
}

variable "stage" {
  description = "The stage of the deployment this is this for"
  default     = "NONE"
}
