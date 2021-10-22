#!/bin/bash
#
# Adapted/ported from:
# - https://github.com/hashicorp/terraform-provider-aws/blob/047d39fedd0183eb695a9fe9db69ca14e4fec88e/aws/data_source_aws_iam_session_context.go
# - https://github.com/aws/aws-sdk-go/blob/v1.40.43/aws/arn/arn.go
#

arn=$1

sectionPartition=1
sectionService=2
sectionRegion=3
sectionAccountID=4
sectionResource=5

IFS=':' read -ra sections <<< "$arn"

section_len=${#sections[@]}
if [[ $section_len != 6 ]]; then
    exit 1
fi

Partition="${sections[${sectionPartition}]}"
Service="${sections[${sectionService}]}"
Region="${sections[${sectionRegion}]}"
AccountID="${sections[${sectionAccountID}]}"
Resource="${sections[${sectionResource}]}"

if [ "$Service" != "sts" ]; then
    echo "{\"issuer_name\": null, \"issuer_arn\": null}"
    exit 0
fi

resource_re='^assumed-role/.{1,}/.{2,}'

if ! [[ "${Resource}" =~ $resource_re ]]; then
    echo "{\"issuer_name\": null, \"issuer_arn\": null}"
    exit 0
fi

IFS='/' read -ra parts <<< "$Resource"
len=${#parts[@]}

if [[ $len < 3 ]]; then
    echo "{\"issuer_name\": null, \"issuer_arn\": null}"
    exit 0
fi

issuer_name="${parts[${len}-2]}"

issuer_arn=$(aws iam get-role --role-name ${issuer_name} --query "Role.Arn" --output text)

echo "{\"issuer_name\": \"${issuer_name}\", \"issuer_arn\": \"${issuer_arn}\"}"
