#!/bin/bash -e

[ -n "$BW_EMAIL" ] || exit 1

# homebrew
set +e
which brew
if [ 0 -ne $? ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"  
fi
set -e
brew install awscli jq bitwarden-cli

# get bitwarden session
if [ $(bw status | jq -r .status) = "unauthenticated" ]; then
  export BW_SESSION=$(bw login $BW_EMAIL --raw)
else
  export BW_SESSION=$(bw unlock --raw)
fi
[ -n "$BW_SESSION" ] || exit 1

# get backup storage credential
export AWS_ACCESS_KEY_ID=$(bw get username backup)
echo AWS_ACCESS_KEY_ID = $AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$(bw get password backup)
export AWS_DEFAULT_REGION=$(bw get item backup | jq -r '.fields[] | select(.name=="region").value')
echo AWS_ACCESS_KEY_ID = $AWS_DEFAULT_REGION
BACKUP_BUCKET=$(bw get item backup | jq -r '.fields[] | select(.name=="bucket").value')
echo AWS_ACCESS_KEY_ID = $BACKUP_BUCKET

# sync backup
set -x
VAULT_DIR=$HOME/vault
mkdir -p $VAULT_DIR
aws s3 sync s3://$BACKUP_BUCKET $VAULT_DIR --dryrun