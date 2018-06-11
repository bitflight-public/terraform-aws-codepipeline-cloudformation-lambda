# terraform-aws-codepipeline-lambda

Create an AWS CodePipeline that automates the deployment of your serverless application

It has 3 stages:
- Source (GitHub)
- Build (CodeBuild)
- Deploy (CloudFormation)

When your pipeline is ready any git push to the branch you connected to this pipeline is going to trigger a deployment

This module has been created to comply with this AWS CI/CD example.
https://docs.aws.amazon.com/lambda/latest/dg/build-pipeline.html

Known issues:
GITHub Token isn't stored in the state and so the state is always updates the token on every apply/plan.
https://github.com/terraform-providers/terraform-provider-aws/issues/2854