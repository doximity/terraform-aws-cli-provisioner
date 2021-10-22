/**
 * # terraform-aws-cli-provisioner
 *
 * A helper module for running the aws cli from within terraform in a `local-exec` provisioner
 *
 * This is a module of last resort.
 *
 * If a terraform resource doesn't exist, of for some other reason you need to run a raw `aws` cli command from within terraform, this module helps you do that.
 *
 * It generates a script that will assume the correct AWS role so you can then execute the cli command in the proper context (meaning, using the same AWS role as the corresponding terraform aws provider).
 *
 */

data "aws_caller_identity" "current" {}

# requires aws provider 3.48.0+
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

# get the aws_caller_identity and aws_iam_session_context externally too, to compare them
data "external" "underlying-role-arn" {
  program = ["aws", "sts", "get-caller-identity"]
}

data "external" "aws_iam_session_context" {
  program = ["${path.module}/get_session_context.sh", data.external.underlying-role-arn.result.Arn]
}
