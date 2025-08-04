function assume-aws-role 
  set creds (aws sts assume-role --role-arn $ROLE_ARN  --role-session-name foz-assumed-role)
  set aws_key_id (echo "$creds" | jq -r '.Credentials.AccessKeyId')
  set aws_secret_key (echo "$creds" | jq -r '.Credentials.SecretAccessKey')
  set aws_session_token (echo "$creds" | jq -r '.Credentials.SessionToken')

  echo $aws_key_id
  echo $aws_secret_key
  echo $aws_session_token

  set -Ux AWS_ACCESS_KEY_ID $aws_key_id
  set -Ux AWS_SECRET_ACCESS_KEY $aws_secret_key
  set -Ux AWS_SESSION_TOKEN $aws_session_token
end

function add-keys-from-aws-profile
    set profile $argv[1]

    if test -z "$profile"
        echo "Usage: add-keys-from-aws-profile <profile-name>"
        return 1
    end

    set aws_key_id (awk -v p="[$profile]" '
        $0 == p {found=1}
        found && $1 == "aws_access_key_id" {print $3; exit}
    ' ~/.aws/credentials)

    set aws_secret_key (awk -v p="[$profile]" '
        $0 == p {found=1}
        found && $1 == "aws_secret_access_key" {print $3; exit}
    ' ~/.aws/credentials)

    set aws_session_token (awk -v p="[$profile]" '
        $0 == p {found=1}
        found && $1 == "aws_session_token" {print $3; exit}
    ' ~/.aws/credentials)

    if test -z "$aws_key_id" -o -z "$aws_secret_key"
        echo "Missing credentials for profile: $profile"
        return 1
    end

  echo $aws_key_id
  echo $aws_secret_key
  echo $aws_session_token

  set -Ux AWS_ACCESS_KEY_ID $aws_key_id
  set -Ux AWS_SECRET_ACCESS_KEY $aws_secret_key
  set -Ux AWS_SESSION_TOKEN $aws_session_token
end

function unset-aws-creds
  set -e AWS_ACCESS_KEY_ID
  set -e AWS_SECRET_ACCESS_KEY
  set -e AWS_SESSION_TOKEN 
end
