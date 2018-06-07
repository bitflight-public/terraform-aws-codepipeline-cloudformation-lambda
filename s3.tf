resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket_prefix = "${module.pipeline_label.id}"
  acl           = "private"
  force_destroy = true
  region        = "${data.aws_region.default.name}"

  # server_side_encryption_configuration {
  #   rule {
  #     apply_server_side_encryption_by_default {
  #       kms_master_key_id = "${module.kms_key.key_arn}"
  #       sse_algorithm     = "aws:kms"
  #     }
  #   }
  # }
}
