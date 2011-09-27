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

require_relative 'lib/string'
require_relative 'lib/exceptions/warning_exception'
require_relative 'lib/rename'
require_relative 'lib/episode'

include Log4r

$opts = Trollop::options do
  opt :verbose, "Verbose mode", :default => true
  opt :debug, "Debug mode", :default => false
  opt :logging, "Enable logging", :default => false
  opt :forreal, "Really rename files", :default => false
end

$log = Log4r::Logger.new ''
$log.level = INFO if $opts[:verbose]
$log.level = DEBUG if $opts[:debug]

$log.outputters = [
  Log4r::StdoutOutputter.new('', :formatter => Log4r::PatternFormatter.new(:pattern => "%d %5l: %m")),
]

$log.outputters << Log4r::FileOutputter.new('', :filename => "log/#{Time.now.strftime('%Y%m%d%H%M%S')}.log") if $opts[:logging]

unless ARGV[0]
  $log.error 'Please specify a directory or files to process.'
  exit
else
  $log.info "** DRY RUN MODE" unless $opts[:forreal]  
  Episode.process ARGV
end