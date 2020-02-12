#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'json'

def get_latest(src)
  match = src.match(/docker\.pkg\.github\.com\/(\w+)\/(\w+)\/(\w+):(\w+)/)
  fail('failed to parse package') unless match
  org, repo, image, _ = match.captures

  query = "query {
    repository(owner:\"#{org}\", name:\"#{repo}\"){
      packages(names:[\"#{image}\"], first: 1) {
        nodes {
          latestVersion {
            version
          }
        }
      }
    }
  }"

  uri = URI('https://api.github.com/graphql')
  req = Net::HTTP.post(
    uri,
    { 'query' => query }.to_json,
    {
      'Accept' => 'application/vnd.github.packages-preview+json',
      'Authorization' => "bearer #{ENV['GITHUB_TOKEN']}"
    }
  )
  fail("Failed GraphQL lookup: #{req.code}") unless req.code_type == Net::HTTPOK

  resp = JSON.parse(req.body)
  resp['data']['repository']['packages']['nodes'][0]['latestVersion']['version']
end

if caller.length == 0
  src = ARGV.shift || fail('image path not provided')
  puts get_latest(src)
end
