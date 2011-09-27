require 'singleton'

class Rename
  include Singleton
  
  attr_reader :config, :tv_db
  attr_accessor :shows, :series, :episodes
  
  def initalize
    @config = nil
    @tv_db = nil
    @shows = nil
    @series = nil
    @episodes = nil
  end
  
  def config
    @config ||= YAML.load_file('config.yaml')
  end

  def tv_db
    @tv_db ||= TvdbParty::Search.new(self.config['api_key'])
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