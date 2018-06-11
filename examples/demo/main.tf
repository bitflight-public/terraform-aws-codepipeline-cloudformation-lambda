## For using Cloudformation set the values deploy_mode and stack_name
## Details on what you can use for DeployMode are found here 
## https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/continuous-delivery-codepipeline-action-reference.html

module "pipeline" {
  source = "../../"

  gh_owner  = "bitflight-public"
  gh_token  = "${data.aws_ssm_parameter.token.value}"
  gh_branch = "master"
  gh_repo   = "terraform-demo-serverless-code"

  namespace              = "cp"
  name                   = "pipeline"
  stage                  = "dev"
  deploy_type            = "LAMBDA"
  action_mode            = "CHANGE_SET_REPLACE"
  stack_name             = "demo-serverless-deploy"
  capabilities           = "CAPABILITY_IAM"
  template_path          = "outputSamTemplate.yaml"
  codebuild_project_name = "${module.codebuild.project_name}"
  codebuild_role_arn     = "${module.codebuild.role_arn}"
}

resource "aws_s3_bucket" "functions" {
  bucket_prefix = "demo-serverless-deploy"
  acl           = "private"
  force_destroy = true
  region        = "${data.aws_region.default.name}"
}

resource "aws_ssm_parameter" "bucket_name" {
  name      = "/serverless/buildspec/s3-bucket-name"
  value     = "${aws_s3_bucket.functions.id}"
  type      = "String"
  overwrite = "true"
}

data "aws_ssm_parameter" "token" {
  name = "GitHubToken"
}

module "codebuild" {
  source             = "git::https://github.com/cloudposse/terraform-aws-codebuild.git?ref=master"
  namespace          = "cp"
  name               = "codebuild"
  stage              = "dev"
  build_image        = "aws/codebuild/nodejs:6.3.1"
  build_compute_type = "BUILD_GENERAL1_SMALL"

  privileged_mode = "true"

  #buildspec       = "${data.template_file.build.rendered}"
  aws_region = "${data.aws_region.default.name}"

  #image_repo_name = "${data.terraform_remote_state.ecr.name}"
  #image_tag       = "latest"
  #github_token    = "${var.gh_token}"
  cache_enabled = "true"
}

output "cf_role_arn" {
  value = "${module.pipeline.cf_role_arn}"
}

output "region" {
  value = "${data.aws_region.default.name}"
}

output "codebuild_project_name" {
  value = "${module.codebuild.project_name}"
}

output "stack_outputs" {
  value = "${module.pipeline.stack_outputs}"
}

data "aws_caller_identity" "default" {}

data "aws_region" "default" {}
