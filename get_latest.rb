#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'json'

def build_query(org, repo, image)
  query = "query {
    repository(owner:\"#{org}\", name:\"#{repo}\"){
      packages(names:[\"#{image}\"], first: 1) {
        nodes {
          latestVersion { version }
        }
      }
    }
  }"
  { 'query' => query }.to_json
end

def parse_source(src)
  match = src.match(%r{docker\.pkg\.github\.com/(\w+)/(\w+)/(\w+):(\w+)})
  raise('failed to parse package') unless match
  match.captures
end

def make_request(body)
  uri = URI('https://api.github.com/graphql')
  req = Net::HTTP.post(
    uri,
    body,
    'Accept' => 'application/vnd.github.packages-preview+json',
    'Authorization' => "bearer #{ENV['GITHUB_TOKEN']}"
  )
  return JSON.parse(req.body) if req.code_type == Net::HTTPOK
  raise("Failed GraphQL lookup: #{req.code}")
end

def get_latest(src)
  org, repo, image, = parse_source(src)
  query = build_query(org, repo, image)
  resp = make_request(query)
  resp['data']['repository']['packages']['nodes'][0]['latestVersion']['version']
end

if caller.empty?
  src = ARGV.shift || raise('image path not provided')
  puts get_latest(src)
end
