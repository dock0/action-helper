#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'json'

repo = ENV['GITHUB_REPOSITORY']

uri = URI("https://api.github.com/repos/#{repo}/dispatches")
req = Net::HTTP.post(
  uri,
  { 'event_type' => 'update-rebuild' }.to_json,
  { 'Authorization' => "bearer #{ENV['GITHUB_TOKEN']}" }
)
fail("Failed query: #{req.code}") unless req.code == "204"
