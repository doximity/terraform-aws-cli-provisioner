package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestCliProvisionerShieldProtection(t *testing.T) {
	t.Parallel()
	unique_name := "cli-provisioner"

	awsRegion := "us-east-1"
	options := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/shield-protection",
		Vars: map[string]interface{}{
			"unique_name": unique_name,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})
	defer terraform.Destroy(t, options)

	terraform.InitAndApply(t, options)
}
