output "bucket_id" {
  value = "${aws_s3_bucket.codepipeline_bucket.bucket}"
}

output "cf_role_arn" {
  value = "${aws_iam_role.cf.arn}"
}

data "aws_cloudformation_stack" "cp" {
  name = "${var.stack_name}"
}

output "stack_outputs" {
  value = "${data.external.cloudformation.result}"
}

output "stack_name" {
  value = "${var.stack_name}"
}

# Pick up the outputs from a cloudformation stack if they are available, and you have access.
# Depdns on Boto3 being installed
# pip3 install boto3
data "external" "cloudformation" {
  program = ["python3", "${path.module}/stack_outputs.py"]

  query = {
    stack_name = "${var.stack_name}"
    region     = "${data.aws_region.default.name}"
  }
}
