set -e
%{ if use-assume-role ~}
%{ if debug-output ~}
echo "Getting new identity: ${assume-role-arn}"
%{ endif ~}

SESSIONDATE=$(date +%s)$(openssl rand -hex 12)
# Export our new vars
eval $(aws sts assume-role \
 --role-arn "${assume-role-arn}" \
 --role-session-name="session$SESSIONDATE" \
 --query 'join(``, [`export `, `AWS_ACCESS_KEY_ID=`,
 Credentials.AccessKeyId, ` ; export `, `AWS_SECRET_ACCESS_KEY=`,
 Credentials.SecretAccessKey, `; export `, `AWS_SESSION_TOKEN=`,
 Credentials.SessionToken])' \
 --output text)

# aws sts does not need security_token, but it is inherited.
unset AWS_SECURITY_TOKEN

# output the new identity for debug purposes
%{ if debug-output ~}
aws sts get-caller-identity
%{ endif ~}
%{ else ~}
# Not assuming a role.
%{ endif ~}
