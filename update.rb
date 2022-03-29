#!/usr/bin/env ruby

require 'date'
require 'uri'
require 'net/http'
require 'json'
require_relative 'get_latest.rb'

def commit(msg)
  ok = system('git', 'config', '--local', 'user.email', 'action@github.com')
  raise('failed to set email') unless ok
  ok = system('git', 'config', '--local', 'user.name', 'Github Action')
  raise('failed to set name') unless ok
  ok = system('git', 'commit', '-m', msg)
  raise('failed to git commit') unless ok
  ok = system('git', 'push', 'origin', 'master')
  raise('failed to git push') unless ok
  puts '::set-output name=updated::yes'
end

def update_dockerfile(org, image, version) # rubocop:disable Metrics/MethodLength
  old = File.read('Dockerfile').lines
  breaker = false
  File.open('Dockerfile', 'w') do |fh|
    old.each do |line|
      if !breaker && line =~ /^FROM ghcr\.io/
        fh << "FROM ghcr.io/#{org}/#{image}:#{version}\n"
        breaker = true
      else
        fh << line
      end
    end
  end
end

def github_registry_bump(src)
  org, image, current = parse_source(src)
  latest = get_latest(src)

  if latest == current
    return scratch_bump if File.exist? 'stamp'
    return
  end

  update_dockerfile(org, image, latest)
  system('git', 'add', 'Dockerfile') || raise('failed to git add')
  commit "Bumped source to #{latest}"
end

def scratch_bump
  datestamp = DateTime.now.strftime('%Y%m%d-%H%M%S')
  File.open('stamp', 'w') { |fh| fh << datestamp }
  system('git', 'add', 'stamp') || raise('failed to git add')
  commit "Bumping on #{datestamp}"
end

src_image = File.read('Dockerfile').lines.grep(/^FROM/).first.split[1]

case src_image
when 'scratch'
  scratch_bump
when /^ghcr\.io/
  github_registry_bump src_image
else
  raise("Unknown source image: #{src_image}") unless File.exist? 'stamp'
  scratch_bump
end
