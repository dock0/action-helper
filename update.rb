#!/usr/bin/env ruby

require 'date'
require 'uri'
require 'net/http'
require 'json'
require_relative 'get_latest.rb'

def commit(msg)
  system('git', 'config', '--local', 'user.email', 'action@github.com') || fail('failed to set email')
  system('git', 'config', '--local', 'user.name', 'Github Action') || fail('failed to set name')
  system('git', 'commit', '--allow-empty', '-m', msg) || fail('failed to git commit')
  system('git', 'push', 'origin', 'master') || fail('failed to git push')
end

def github_registry_bump(src)
  match = src.match(/docker\.pkg\.github\.com\/(\w+)\/(\w+)\/(\w+):(\w+)/)
  fail('failed to parse package') unless match
  org, repo, image, current = match.captures
  latest = get_latest(src)

  if latest == current
    return scratch_bump if ENV['ALWAYS_BUMP']
    return
  end

  old = File.read('Dockerfile').lines
  breaker = false
  File.open('Dockerfile', 'w') do |fh|
    old.each do |line|
      if !breaker && line =~ /^FROM docker\.pkg\.github\.com/
        fh << "FROM docker.pkg.github.com/#{org}/#{repo}/#{image}:#{latest}\n"
        breaker = true
      else
        fh << line
      end
    end
  end

  system('git', 'add', 'Dockerfile') || fail('failed to git add')
  commit "Bumped source to #{latest}"
end

def scratch_bump
  datestamp = DateTime.now.strftime("%Y%m%d-%H%M%S")
  File.open('stamp', 'w') { |fh| fh << datestamp }
  system('git', 'add', 'stamp') || fail('failed to git add')
  commit "Bumping on #{datestamp}"
end

src_image = File.read('Dockerfile').lines.grep(/^FROM/).first.split[1]

case src_image
when "scratch"
  scratch_bump
when /^docker.pkg.github.com/
  github_registry_bump src_image
else
  fail("Unknown source image: #{src_image}") unless ENV['ALWAYS_BUMP']
  scratch_bump
end
