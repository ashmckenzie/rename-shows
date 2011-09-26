#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'pathname'
require 'fileutils'
require 'trollop'
require 'yaml'
require 'pry'
require 'awesome_print'
require 'log4r/outputter/datefileoutputter'

require_relative 'lib/episode'

include Log4r

$log = Log4r::Logger.new ''

$log.outputters = [
  Log4r::StdoutOutputter.new('', :formatter => Log4r::PatternFormatter.new(:pattern => "%d %5l: %m")),
  Log4r::FileOutputter.new('', :filename => "log/#{Time.now.strftime('%Y%m%d%H%M%S')}.log")
]

$config = YAML.load_file('config.yaml')

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

unless ARGV[0]
  $log.error 'Please specify a directory or files to process.'
  exit
else
  entries = []
  $log.info 'Looking for entries..'
  ARGV.each do |arg|
    entries += Dir["#{arg.chomp('/')}/**/*"].reject { |x| File.directory?(x) || !File.exist?(x) }
  end
  $log.info "#{entries.count} entries found."
end

entries.each do |entry|
  e = Episode.new(entry)
  e.rename!
end
