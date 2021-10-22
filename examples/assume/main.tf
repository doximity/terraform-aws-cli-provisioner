# ----------- providers ------------------

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = var.role_to_assume
  }

  alias = "deployment"
}

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = data.external.aws_iam_session_context.result.issuer_arn
  }

  alias = "myself"
}

# inception - using the script in the module to get the underlying role, so we can set up to assume the same role,
# just to test that we should not try to re-assume the current role if that's the case (using "myself" provider)
data "external" "aws_iam_session_context" {
  program = ["${path.module}/../../get_session_context.sh", data.external.underlying-role-arn.result.Arn]
}
data "external" "underlying-role-arn" {
  program = ["aws", "sts", "get-caller-identity"]
}



# -------------- provisioner modules ------------------

module "default" {
  source       = "../.."
  debug_output = false
}

module "deployment" {
  source       = "../.."
  debug_output = false
  providers = {
    aws = aws.deployment
  }
}

module "myself" {
  source       = "../.."
  debug_output = false
  providers = {
    aws = aws.myself
  }
}



# ---------------- test outputs ---------------

## write a file to output the current role (using the module's generated script)
resource "local_file" "default" {
  filename = "${path.module}/default.sh"
  content  = <<CMD
#!/bin/bash
${module.default.script}
aws sts get-caller-identity
  CMD
}

## run the file to capture the current role in terraform
data "external" "default-identity" {
  program    = ["${path.module}/default.sh"]
  depends_on = [local_file.default]
}

## output the current role
output "default_identity_arn" {
  value = data.external.default-identity.result.Arn
}


## write a file to output the current role (using the module's generated script)
resource "local_file" "deployment" {
  filename = "${path.module}/deployment.sh"
  content  = <<CMD
#!/bin/bash
${module.deployment.script}
aws sts get-caller-identity
  CMD
}

## run the file to capture the current role in terraform
data "external" "deployment-identity" {
  program    = ["${path.module}/deployment.sh"]
  depends_on = [local_file.deployment]
}

## output the current role
output "deployment_identity_arn" {
  value = data.external.deployment-identity.result.Arn
}


## write a file to output the current role (using the module's generated script)
resource "local_file" "myself" {
  filename = "${path.module}/myself.sh"
  content  = <<CMD
#!/bin/bash
${module.myself.script}
aws sts get-caller-identity
  CMD
}

## run the file to capture the current role in terraform
data "external" "myself-identity" {
  program    = ["${path.module}/myself.sh"]
  depends_on = [local_file.myself]
}

## output the current role
output "myself_identity_arn" {
  value = data.external.myself-identity.result.Arn
}
