class WarningException < Exception
end

class Episode
  attr_reader :show, :season, :episode, :title
  
  def initialize path
    @file = Pathname.new(path)
  end
    
  def rename!
    begin
      lookup
    rescue Interrupt
      raise
    rescue WarningException => e
      $log.warn e.message
      return false
    rescue Exception => e
      $log.error "#{e.message}, #{e.backtrace.last}"
      return false
    end

    if @file != suggested_file
      $log.info "Renaming '#{@file.basename} to '#{suggested_file.basename}" if $verbose
      FileUtils.mv @file, suggested_file if $forreal
    else
      $log.info "Has correct filename '#{@file}'" if $verbose
    end

    true
  end
  
  private

  def lookup
    $log.debug "Looking up '#{@file}'" if $debug

    unless (match = @file.basename.to_s.match(/s(\d+)e(\d+)\.?.*\.(\w+)$/i))
      $log.error "Did not match regex '#{@file}'"
      return false
    end

    @show = @file.dirname.to_s.split('/')[-2]
    @season = match[1]
    @episode = match[2]
    @extension = match[3].downcase

    show_cache_file = "#{show}/show.marshal"
    unless ($shows[show] ||= read_cache(show_cache_file))
      $shows[show] = $tvdb.search(show).first
      cache show_cache_file, $shows[show]
    else
      $log.debug "Cache hit for show '#{show}'" if $debug
    end

    series_id = $shows[show]["seriesid"]
    series_cache_file = "#{show}/series_#{season}/series.marshal"
    unless ($series[series_id] ||= read_cache(series_cache_file))
      $series[series_id] = $tvdb.get_series_by_id(series_id)
      cache series_cache_file, $series[series_id]
    else
      $log.debug "Cache hit for show '#{show}', season '#{season}'" if $debug
    end

    episode_cache_file = "#{show}/series_#{season}/episode_#{episode}.marshal"
    unless ($episodes["#{show}-#{season}-#{episode}"] ||= read_cache(episode_cache_file))
      if ep = $series[series_id].get_episode(season.to_i, episode.to_i)
        $episodes["#{show}-#{season}-#{episode}"] = ep
        cache episode_cache_file, ep
      else
        raise WarningException, "Cannot find episode information for '#{@file}'"
      end
    else
      $log.debug "Cache hit for show '#{show}', season '#{season}', episode '#{episode}'" if $debug
    end

    @title = $episodes["#{show}-#{season}-#{episode}"].name

    true
  end
  
  def read_cache file
    file = "./cache/#{file}"
    $log.debug "Attemping to read cache from '#{file}" if $debug
    return false unless File.exist? file
    Marshal.load File.read(file)
  end
  
  def cache file, content
    file = "./cache/#{file}"
    file_dir = File.dirname(file)
    FileUtils.mkdir_p(file_dir) unless File.exist? file_dir
    f = File.new(file, 'w')
    f.puts Marshal.dump(content)
    f.close
  end

  def suggested_file
    @suggested_file ||= Pathname.new "#{@file.dirname}/#{dot(show)}.S#{pad(season)}E#{pad(episode)}.#{dot(title)}.#{@extension}"
  end
  
  def pad str
    sprintf('%02s', str.to_s)
  end
  
  def dot str
    str.chomp(' ').gsub(/&/, 'and').gsub(/(\?|:|-|_|!|,|\)|\()/, '').gsub(/\w+/) { |s| s.capitalize }.gsub(/\s+/, '.')
  end
end
