#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'json'

DOCKER_SRC = %r{ghcr\.io/([\w-]+)/([\w-]+):([\w-]+)}

def parse_source(src)
  match = src.match(DOCKER_SRC)
  raise('failed to parse package') unless match
  match.captures
end

def make_request(org, image)
  uri = URI("https://api.github.com/orgs/#{org}/packages/container/#{image}/versions")
  req = Net::HTTP.get_response(
    uri,
    'Accept' => 'application/vnd.github.v3+json',
    'Authorization' => "token #{ENV['GITHUB_TOKEN']}"
  )
  return JSON.parse(req.body) if req.code_type == Net::HTTPOK
  raise("Failed API lookup: #{req.code}")
end

def get_latest(src)
  org, image, = parse_source(src)
  resp = make_request(org, image)
  tags = resp.first.dig('metadata', 'container', 'tags')
  # this checks if latest is in the tag list *and* removes it, leaving just the datestamp tag
  raise("Latest image doesn't have latest tag") unless tags.delete 'latest'
  return tags.first
end

if caller.empty?
  src = ARGV.shift || raise('image path not provided')
  puts get_latest(src)
end
