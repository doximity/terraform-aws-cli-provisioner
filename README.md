# terraform-aws-cli-provisioner

A helper module for running the aws cli from within terraform in a `local-exec` provisioner

This is a module of last resort.

If a terraform resource doesn't exist, of for some other reason you need to run a raw `aws` cli command from within terraform, this module helps you do that.

It generates a script that will assume the correct AWS role so you can then execute the cli command in the proper context (meaning, using the same AWS role as the corresponding terraform aws provider).

```hcl
provider "aws" {
  # we are assuming a role to work with AWS. In this example it's obvious which one because
  # it's right here, but in the real world (in a module) you don't know in advance which
  # role you'll need to assume. The `provisioner` module below figures it out using AWS API calls
  # so that when the scripts below run, they will automatically run under the correct AWS role
  # (including if no role is assumed at all, it will just do nothing!)
  assume_role {
    role_arn = var.role_to_assume
  }
}


resource "aws_shield_protection" "this" {
  name         = "a-name${var.unique_name}"
  resource_arn = aws_alb.alb.arn

  # There is no terraform resource for associating a health check with a shield protection
  # So we use the provisioner to associate it.
  provisioner "local-exec" {
    command = <<COMMAND
      ##
      # The `module.provisioner.script` script is created by the "provisioner" module below.
      # It detects which role terraform is currently assuming, and generates the script to
      # set environment variables to re-assume that role.
      #
      ${module.provisioner.script}
      aws shield associate-health-check \
      --protection-id ${self.id} \
      --health-check-arn "arn:aws:route53:::healthcheck/${aws_route53_health_check.this.id}"
    COMMAND
  }
}

resource "null_resource" "deprovisioner" {
  # these `triggers` act as a "cache" of these dependent values, so that at destroy-time
  # they still exist and refer to the same thing they used to refer to when those resources
  # existed (in case they are also being destroyed, or replaced, which is likely given this
  # usage pattern)
  triggers = {
    script           = module.provisioner.script
    protection_id    = aws_shield_protection.this.id
    health_check_arn = aws_route53_health_check.this.id
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<COMMAND
      ##
      # When destroying or re-creating the `aws_shield_protection`, it will fail to be destroyed
      # if there is still a health-check associated with it. So we have to use this "destroy-time"
      # provisioner to disassociate it first, before destroying the parent resource.
      #
      # destroy-time provisioners only allow us to use `self.` dependencies, so we use self.triggers.x
      # to refer to the resources we need to work with.
      ${self.triggers.script}
      aws shield disassociate-health-check \
      --protection-id ${self.triggers.protection_id} \
      --health-check-arn "arn:aws:route53:::healthcheck/${self.triggers.health_check_arn}"
    COMMAND
  }
}


module "provisioner" {
  # Since we are using the default provider no provider argument is necessary here.
  # But if the resource we are "provisioning" was using a different provider alias, we would
  # need to make sure this provisioner is using that same provider so that it generates the
  # correct corresponding assume role commands
  source = "../.."
}

```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.48.0 |
| <a name="provider_external"></a> [external](#provider\_external) | ~> 2.1 |
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.48.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.1 |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_debug_output"></a> [debug\_output](#input\_debug\_output) | Whether to output some minimal debug information from the generated script about which role is being assumed by the script. | `bool` | `true` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_script"></a> [script](#output\_script) | A string that contains a bash script that will assume the correct role for running an aws cli command |

