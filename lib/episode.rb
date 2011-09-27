class Episode
  attr_reader :show, :season, :series_id, :episode, :title
  
  def initialize path
    @rename = Rename.instance
    @tv_db = @rename.tv_db
    @file = Pathname.new(path)
  end
  
  def self.process args
    entries = []
    
    args.each do |arg|
      if File.directory? arg
        entries += Dir["#{arg.chomp('/')}/**/*"].reject do |x| 
          File.directory?(x) || 
          !File.exist?(x) ||
          !self.is_video?(File.basename(x))
        end
      elsif File.file?(arg) && self.is_video?(arg)
        entries << arg
      end
    end
    
    $log.info "#{entries.count} entries found."
    
    entries.sort.each do |entry|
      e = self.new(entry)
      e.rename! $opts[:forreal]
    end
  end
  
  def self.is_video? file
    file.downcase.match(/\.(mp4|m4v|mov|divx|xvid|avi)$/)
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
      $log.error "#{e.message} - Run with --debug for more detail"
      if $opts[:debug]
        puts e.backtrace
        binding.pry
      end
      return false
    end

    $log.debug "@file         =[#{@file}]"
    $log.debug "suggested_file=[#{suggested_file}]"
    $log.debug "@file.to_s == suggested_file.to_s = #{@file.to_s == suggested_file.to_s}"

    unless same_file?(@file, suggested_file)
      $log.info "Renaming '#{@file.basename}' to '#{suggested_file.basename}"
      rename @file, suggested_file if forreal
    else
      $log.info "Has correct filename '#{@file}'"
    end
    
    $log.debug ''
  end
  
  private

  def rename old_file, new_file
    FileUtils.mv old_file, new_file
  end

  def lookup
    $log.debug "Looking up '#{@file}'"

    unless (match = @file.basename.to_s.match(/(.+)(?:\.|_|-| )?s(\d+)e(\d+)(?:\.|_|-| )?.*\.(\w+)$/i))
      raise WarningException, "Did not match regex '#{@file}'"
    end

    @show = match[1].gsub(/\./, ' ')
    @season = match[2]
    @episode = match[3]
    @extension = match[4].downcase

    lookup_show
    lookup_series
    lookup_episode

    @title = @rename.episodes["#{show}-#{season}-#{episode}"].name
  end
  
  def lookup_show
    show_cache_file = "#{show}/show.marshal"
    unless (@rename.shows[show] ||= read_cache(show_cache_file))
      $log.debug "No cache for show '#{show}'"
      if (@rename.shows[show] = @tv_db.search(show).first)
        cache show_cache_file, @rename.shows[show]
      else
        raise WarningException, "Could not find a match for '#{@file}'"
      end
    else
      $log.debug "Cache hit for show '#{show}'"
    end
  end

  def lookup_series
    @series_id = @rename.shows[show]["seriesid"]
    series_cache_file = "#{show}/series_#{season}/series.marshal"
    unless (@rename.series[@series_id] ||= read_cache(series_cache_file))
      $log.debug "No cache for show '#{show}', season '#{season}'"
      @rename.series[@series_id] = @tv_db.get_series_by_id(@series_id)
      cache series_cache_file, @rename.series[@series_id]
    else
      $log.debug "Cache hit for show '#{show}', season '#{season}'"
    end
  end

  def lookup_episode
    episode_cache_file = "#{show}/series_#{season}/episode_#{episode}.marshal"
    unless (@rename.episodes["#{show}-#{season}-#{episode}"] ||= read_cache(episode_cache_file))
      $log.debug "No cache for show '#{show}', season '#{season}', episode '#{episode}'"
      if ep = @rename.series[@series_id].get_episode(season.to_i, episode.to_i)
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
    @file.to_s.downcase == suggested_file.to_s.downcase
  end

  def suggested_file
    @suggested_file ||= Pathname.new("#{@file.dirname}/#{normalise(show)}.S#{pad(season)}E#{pad(episode)}.#{normalise(title.remove_non_ascii)}.#{@extension}")
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
