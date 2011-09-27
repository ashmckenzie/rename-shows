class String
  def remove_non_ascii
    require 'iconv'
    Iconv.conv('ASCII//IGNORE', 'UTF8', self)
  end
end