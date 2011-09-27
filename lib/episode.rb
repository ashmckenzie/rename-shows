class WarningException < Exception
end

class Episode
  attr_reader :show, :season, :episode, :title
  
  def initialize path
    @rename = Rename.instance
    @tv_db = @rename.tv_db
    @file = Pathname.new(path)
  end
    
  def rename! forreal=false
    begin
      lookup
    rescue Interrupt
      raise
    rescue WarningException => e
      $log.warn e.message
      return false
    rescue Exception => e
      $log.error "#{e.message}, #{e.backtrace.last}"
      puts e.backtrace
      binding.pry if $opts[:debug]
      return false
    end

    $log.debug "@file         =[#{@file}]"
    $log.debug "suggested_file=[#{suggested_file}]"
    $log.debug "#{@file.to_s != suggested_file.to_s}"

    if same_file?(@file, suggested_file)
      $log.info "Renaming '#{@file.basename} to '#{suggested_file.basename}"
      rename @file, suggested_file if forreal
    else
      $log.info "Has correct filename '#{@file}'"
    end

    true
  end
  
  private

  def rename old_file, new_file
    FileUtils.mv old_file, new_file
  end

  def lookup
    $log.debug "Looking up '#{@file}'"

    unless (match = @file.basename.to_s.match(/(.+)\.s(\d+)e(\d+)\.?.*\.(\w+)$/i))
      raise WarningException, "Did not match regex '#{@file}'"
    end

    @show = match[1].gsub(/\./, ' ')
    @season = match[2]
    @episode = match[3]
    @extension = match[4].downcase

    $log.debug "Looking for show '#{show}'"

    lookup_show
    lookup_series
    lookup_episode

    @title = @rename.episodes["#{show}-#{season}-#{episode}"].name

    true
  end
  
  def lookup_show
    show_cache_file = "#{show}/show.marshal"
    unless (@rename.shows[show] ||= read_cache(show_cache_file))
      @rename.shows[show] = @tv_db.search(show).first
      cache show_cache_file, @rename.shows[show]
    else
      $log.debug "Cache hit for show '#{show}'"
    end
  end

  def lookup_series
    series_id = @rename.shows[show]["seriesid"]
    series_cache_file = "#{show}/series_#{season}/series.marshal"
    unless (@rename.series[series_id] ||= read_cache(series_cache_file))
      @rename.series[series_id] = @tv_db.get_series_by_id(series_id)
      cache series_cache_file, @rename.series[series_id]
    else
      $log.debug "Cache hit for show '#{show}', season '#{season}'"
    end
  end

  def lookup_episode
    episode_cache_file = "#{show}/series_#{season}/episode_#{episode}.marshal"
    unless (@rename.episodes["#{show}-#{season}-#{episode}"] ||= read_cache(episode_cache_file))
      if ep = @rename.series[series_id].get_episode(season.to_i, episode.to_i)
        @rename.episodes["#{show}-#{season}-#{episode}"] = ep
        cache episode_cache_file, ep
      else
        raise WarningException, "Cannot find episode information for '#{@file}'"
      end
    else
      $log.debug "Cache hit for show '#{show}', season '#{season}', episode '#{episode}'"
    end
  end  
  
  def read_cache file
    file = "./cache/#{file}"
    $log.debug "Attemping to read cache from '#{file}"
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

  def same_file? file1, file2
    @file.to_s.downcase != suggested_file.to_s.downcase
  end

  def suggested_file
    @suggested_file ||= Pathname.new "#{@file.dirname}/#{normalise(show)}.S#{pad(season)}E#{pad(episode)}.#{normalise(title)}.#{@extension}"
  end
  
  def pad str
    sprintf('%02s', str.to_s)
  end

  def normalise str
    cleanup(str).gsub(/\s+/, '.').split('.').each { |s| s.capitalize! }.join('.')
  end
  
  def cleanup str
    str.chomp(' ').gsub(/&/, 'and').gsub(/\//, ' ').gsub(/(\?|:|-|_|!|,|\)|\(|')/, '')
  end  
end