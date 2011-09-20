class Episode
  attr_reader :show, :season, :episode, :title
  
  def initialize path
    @file = Pathname.new(path)
    match = @file.basename.to_s.match(/s(\d\d)e(\d\d).*\.(\w+)$/i)
    @show = @file.dirname.to_s.split('/')[-2]
    @season = match[1]
    @episode = match[2]
    @extension = match[3].downcase
    lookup
  end
    
  def rename!
    if @file != suggested_file
    $log.info "Moving '#{@file} to '#{suggested_file}" if $verbose
      FileUtils.mv @file, suggested_file if $forreal
    end
  end
  
  private

  def lookup
    $log.debug "Looking up '#{@file}'" if $debug
    unless $shows[show]
      $shows[show] = $tvdb.search(show).first
    end
    series_id = $shows[show]["seriesid"]
    unless $series[series_id]
      $series[series_id] = $tvdb.get_series_by_id(series_id)
    end
    unless $episodes["#{show}-#{season}-#{episode}"]
      ep = $series[series_id].get_episode(season.to_i, episode.to_i)
      $episodes["#{show}-#{season}-#{episode}"] = ep
    end
    @title = $episodes["#{show}-#{season}-#{episode}"].name
  end

  def suggested_file
    @suggested_file ||= Pathname.new "#{@file.dirname}/#{dot(show)}.S#{pad(season)}E#{pad(episode)}.#{dot(title)}.#{@extension}"
  end
  
  def pad str
    sprintf('%02s', str.to_s)
  end
  
  def dot str
    str.chomp(' ').gsub(/&/, 'and').gsub(/(\?|:|-|_)/, '').gsub(/\w+/) { |s| s.capitalize }.gsub(/\s+/, '.')
  end
end