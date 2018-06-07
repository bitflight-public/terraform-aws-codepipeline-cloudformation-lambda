output "bucket_id" {
  value = "${aws_s3_bucket.codepipeline_bucket.bucket}"
}

output "cf_role_arn" {
  value = "${aws_iam_role.cf.arn}"
}
