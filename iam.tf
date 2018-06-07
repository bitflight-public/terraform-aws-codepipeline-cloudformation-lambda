resource "aws_iam_role" "codepipeline" {
  name_prefix = "${module.pipeline_label.id}"

  assume_role_policy = "${data.aws_iam_policy_document.cp_assume_role_policy.json}"
}

data "aws_iam_policy_document" "cp_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com", "codebuild.amazonaws.com", "cloudformation.amazonaws.com"]
    }
  }

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.default.account_id}:root"]
    }
  }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name_prefix = "s3-policy-codebuild-${module.pipeline_label.id}"
  role        = "${var.codebuild_role_arn}"

  ## TODO: Make this aws_iam_policy_document
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:*",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect":"Allow",
      "Action": ["ecr:*", "ssm:GetParameters", "codebuild:StartBuild"],
      "Resource": ["*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name_prefix = "cp-${module.pipeline_label.id}"
  role        = "${aws_iam_role.codepipeline.id}"

  ## TODO: Make this aws_iam_policy_document
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:*",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild",
        "ssm:GetParameters",
        "cloudformation:DescribeChangeSet",
        "cloudformation:DescribeStacks",
        "cloudformation:ExecuteChangeSet"
      ],
      "Resource": "*"
    },
    {
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::codepipeline*"
      ],
      "Effect": "Allow"
    },
    {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": "${aws_iam_role.cf.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_lambda_execution_policy" {
  name_prefix = "lambda-${module.pipeline_label.id}"
  role        = "${aws_iam_role.codepipeline.id}"    //"${var.codebuild_role_arn}"

  ## TODO: Make this aws_iam_policy_document
  policy = <<EOF
{
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::codepipeline*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "lambda:*"
      ],
      "Resource": [
        "arn:aws:lambda:${data.aws_region.default.name}:${data.aws_caller_identity.default.account_id}:function:*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "apigateway:*"
      ],
      "Resource": [
        "arn:aws:apigateway:${data.aws_region.default.name}::*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "iam:GetRole",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:PutRolePolicy"
      ],
      "Resource": [
        "arn:aws:iam::${data.aws_caller_identity.default.account_id}:role/*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "iam:AttachRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:DetachRolePolicy"
      ],
      "Resource": [
        "arn:aws:iam::${data.aws_caller_identity.default.account_id}:role/*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "iam:PassRole",
        "ssm:GetParameters"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "cloudformation:CreateChangeSet"
      ],
      "Resource": [
        "arn:aws:cloudformation:${data.aws_region.default.name}:aws:transform/Serverless-2016-10-31"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "codedeploy:CreateApplication",
        "codedeploy:DeleteApplication",
        "codedeploy:RegisterApplicationRevision"
      ],
      "Resource": [
        "arn:aws:codedeploy:${data.aws_region.default.name}:${data.aws_caller_identity.default.account_id}:application:*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "codedeploy:CreateDeploymentGroup",
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment"
      ],
      "Resource": [
        "arn:aws:codedeploy:${data.aws_region.default.name}:${data.aws_caller_identity.default.account_id}:deploymentgroup:*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource": [
        "arn:aws:codedeploy:${data.aws_region.default.name}:${data.aws_caller_identity.default.account_id}:deploymentconfig:*"
      ],
      "Effect": "Allow"
    }
  ],
  "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment_ECR" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerServiceFullAccess"
  role       = "${aws_iam_role.codepipeline.id}"
}

resource "aws_iam_role" "cf" {
  name_prefix = "cf-action-role-${module.pipeline_label.id}"

  ## TODO: Make this aws_iam_policy_document
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.default.account_id}:root"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["cloudformation.amazonaws.com", "codepipeline.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_pipeline_policy" {
  name_prefix = "codebuild_pipeline_policy"
  role        = "${var.codebuild_role_arn}"

  ## TODO: Make this aws_iam_policy_document
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:DescribeChangeSet",
        "cloudformation:DescribeStacks",
        "cloudformation:CreateChangeSet",
        "ssm:GetParameters"
      ],
      "Resource": "*"
    },{
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*",
        "*"
      ]
    },
    {
      "Action": [
        "iam:PassRole"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cloudformation_policy_attachment_lambda" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
  role       = "${aws_iam_role.cf.id}"
}

resource "aws_iam_role_policy" "cloudformation_action_policy" {
  name_prefix = "cloudformation_action_policy"
  role        = "${aws_iam_role.cf.id}"

  ## TODO: Make this aws_iam_policy_document
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "cloudformation:DescribeChangeSet",
        "cloudformation:DescribeStacks",
        "cloudformation:CreateChangeSet"
      ],
      "Resource": "*"
    },{
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Action": [
        "iam:PassRole",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:DeleteRole",
        "iam:PutRolePolicy",
        "iam:GetRoll"
      ],
      "Resource": [
        "arn:aws:sts::${data.aws_caller_identity.default.account_id}:assumed-role/${aws_iam_role.cf.id}/*",
        "arn:aws:iam::${data.aws_caller_identity.default.account_id}:role/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}
