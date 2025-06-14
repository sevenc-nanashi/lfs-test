#!/usr/bin/env bash
set -e

# gitに自作credential helperを設定
RUBY_PATH=$(which ruby)
echo "Using Ruby at: $RUBY_PATH"
git config set --all credential.helper "cache --timeout=$($RUBY_PATH ./credential_helper.rb fetch_timeout)"
git config set --append credential.helper "$RUBY_PATH ./credential_helper.rb"

# lfsを設定
echo "Setting up Git LFS..."
git lfs install
git lfs pull