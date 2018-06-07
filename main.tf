module "pipeline_label" {
  source    = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=tags/0.1.2"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "pipeline"
  tags      = "${merge(map("ManagedBy", "Terraform"), var.tags)}"
}

module "kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=master"
  namespace               = "${var.namespace}"
  stage                   = "${var.stage}"
  name                    = "pipeline"
  tags                    = "${merge(map("ManagedBy", "Terraform"), var.tags)}"
  description             = "KMS key for ${module.pipeline_label.id}"
  deletion_window_in_days = 10
  enable_key_rotation     = "false"
  alias                   = "alias/${module.pipeline_label.id}"
}

resource "aws_codepipeline" "pipeline" {
  name       = "${module.pipeline_label.id}"
  role_arn   = "${aws_iam_role.codepipeline.arn}"
  depends_on = ["aws_iam_role.codepipeline", "aws_iam_role.cf"]

  artifact_store {
    location = "${aws_s3_bucket.codepipeline_bucket.bucket}"
    type     = "S3"

    # encryption_key {
    #   id   = "${module.kms_key.key_arn}"
    #   type = "KMS"
    # }
  }

  stage = [{
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["app_artifacts"]

      configuration {
        OAuthToken           = "${var.gh_token}"
        Owner                = "${var.gh_owner}"
        Repo                 = "${var.gh_repo}"
        Branch               = "${var.gh_branch}"
        PollForSourceChanges = "true"
      }
    }
  },
    {
      name = "Build"

      action {
        name             = "Build"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["app_artifacts"]
        output_artifacts = ["task_artifacts"]
        version          = "1"

        configuration {
          ProjectName = "${var.codebuild_project_name}"
        }
      }
    },
    {
      name = "Deploy"

      action {
        name            = "CreateChangeSet"
        version         = "1"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "CloudFormation"
        input_artifacts = ["task_artifacts"]
        role_arn        = "${aws_iam_role.cf.arn}"
        run_order       = 1

        configuration {
          ActionMode    = "CHANGE_SET_REPLACE"
          StackName     = "${var.stack_name}"
          ChangeSetName = "${var.stack_name}-changes"
          Capabilities  = "${var.capabilities}"
          RoleArn       = "${aws_iam_role.cf.arn}"
          TemplatePath  = "task_artifacts::${var.template_path}"
        }
      }

      action {
        name      = "DeployChangeSet"
        version   = "1"
        category  = "Deploy"
        owner     = "AWS"
        provider  = "CloudFormation"
        run_order = 2

        configuration {
          ActionMode    = "CHANGE_SET_EXECUTE"
          StackName     = "${var.stack_name}"
          ChangeSetName = "${var.stack_name}-changes"
        }
      }
    },
  ]
}
