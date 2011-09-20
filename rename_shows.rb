#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'pathname'
require 'fileutils'
require 'logger'
require 'trollop'
require 'yaml'
require 'pry'

require_relative 'lib/episode'

$config = YAML.load_file('config.yaml')
$log = Logger.new(STDOUT)

$tvdb = TvdbParty::Search.new($config['api_key'])

$shows = {}
$series = {}
$episodes = {}

opts = Trollop::options do
  opt :verbose, "Verbose mode", :default => true
  opt :debug, "Debug mode", :default => false
  opt :forreal, "Really rename files", :default => false
end

$verbose = opts[:verbose]
$debug = opts[:debug]
$forreal = opts[:forreal]

unless ARGV[0] && File.directory?(ARGV[0])
  $log.error 'ERROR: Please specify a directory'
  exit
end

Dir["#{ARGV[0]}/**/*"].each do |entry|
  next if File.directory? entry
  e = Episode.new entry
  e.rename!
end