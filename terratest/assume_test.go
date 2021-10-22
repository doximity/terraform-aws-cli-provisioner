package test

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"gotest.tools/assert"
)

func TestCliProvisionerAssume(t *testing.T) {
	t.Parallel()
	awsRegion := "us-east-1"
	options := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/assume",
		Vars:         map[string]interface{}{},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})
	defer terraform.Destroy(t, options)

	terraform.InitAndApply(t, options)

	defaultIdentityArn := terraform.Output(t, options, "default_identity_arn")
	deploymentIdentityArn := terraform.Output(t, options, "deployment_identity_arn")
	myselfIdentityArn := terraform.Output(t, options, "myself_identity_arn")

	assert.Assert(t, strings.Contains(defaultIdentityArn, "assumed-role/github-actions-terraform-aws-cli-provisioner/"), "The 'default' provider should produce a script that does not assume a new role")
	assert.Assert(t, strings.Contains(myselfIdentityArn, "assumed-role/github-actions-terraform-aws-cli-provisioner/"), "The 'myself' provider should not attempt to re-assume the same role")
	assert.Assert(t, strings.Contains(deploymentIdentityArn, "assumed-role/terraform-aws-cli-provisioner-assumable/"), "The 'deployment' provider should produce a script that assumes this role")
}
