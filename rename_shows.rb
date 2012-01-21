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

require_relative 'lib/exceptions/warning_exception'
require_relative 'lib/rename'
require_relative 'lib/episode'

$opts = Trollop::options do
  opt :noverbose, "No Verbose mode", :default => false
  opt :debug, "Debug mode", :default => false
  opt :logging, "Enable logging", :default => false
  opt :forreal, "Really rename files", :default => false
end

$log = Logging.logger(STDOUT)

$log.level = :info

$log.level = 'off' if $opts[:noverbose]
$log.level = :debug if $opts[:debug]

unless ARGV[0]
  $log.error 'Please specify a directory or files to process.'
  exit
else
  $log.info "** DRY RUN MODE" unless $opts[:forreal]  
  Episode.process ARGV
end