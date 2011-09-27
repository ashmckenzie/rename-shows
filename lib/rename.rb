require 'singleton'

class Rename
  include Singleton
  
  attr_reader :config, :tv_db
  attr_accessor :shows, :series, :episodes
  
  def initalize
    @config ||= YAML.load_file('config.yaml')
    @tv_db ||= TvdbParty::Search.new($config['api_key'])
    
    @shows = nil
    @series = nil
    @episodes = nil
  end
  
  def shows
    @shows ||= {}
  end
  
  def series
    @series ||= {}
  end
  
  def episodes
    @episodes ||= {}
  end      
end