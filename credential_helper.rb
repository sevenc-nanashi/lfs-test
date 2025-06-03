# frozen_string_literal: true
# hf.co用の自作credential helper。
require "base64"
require "json"

def receive_info
  info = {}
  while line = STDIN.gets&.chomp
    break if line.strip.empty?
    key, value = line.split("=", 2)
    info[key] = value
  end

  info
end

def get_lfs_repo
  lfs_url = `git config -f .lfsconfig --get lfs.url`
  lfs_url.match(%r{^https://hf.co/([^/]+/[^/]+)/info/lfs$})&.[](1) or
    raise "LFS URL not matched: #{lfs_url}"
end

def fetch_lfs_upload_info
  ssh_options = {
    "StrictHostKeyChecking" => "no",
    "PreferredAuthentications" => "publickey",
    "PasswordAuthentication" => "no"
  }
  repo = get_lfs_repo
  auth_info_json =
    `ssh git@hf.co #{
      ssh_options.map { |k, v| "-o #{k}=#{v}" }.join(" ")
    } git-lfs-authenticate #{repo} upload`
  JSON.parse(auth_info_json, symbolize_names: true)
end
def fetch_credential
  fetch_lfs_upload_info => { header: { Authorization: authorization } }
  authorization.split(" ", 2) => ["Basic", basic_payload]
  Base64.decode64(basic_payload).split(":", 2) => [user, token]

  [user, token]
end
def fetch_timeout
  fetch_lfs_upload_info => { expires_in: timeout }

  timeout
end

action = ARGV[0]
case action
when "get"
  info = receive_info

  unless info["protocol"] == "https" &&
           %w[hf.co huggingface.co].include?(info["host"])
    exit 0
  end

  # hf.coのアクセストークンを取得
  user, token = fetch_credential
  puts "username=#{user}"
  puts "password=#{token}"
when "fetch_timeout"
  # アクセストークンの有効期限を取得
  # 念のため60秒の余裕を持たせる
  puts (fetch_timeout - 60)
when "fill"
  exit 0
when "erase"
  exit 0
else
  puts "Unknown action: #{action}"
  exit 1
end
