# Scraper for geo-located .gov sites, getting us our goodies.
class DotGov
  
  SOURCES = {
    :quakes => 'http://earthquake.usgs.gov/eqcenter/catalogs/7day-M2.5.xml'
  }
  
  MAGNITUDE_FINDER = /\AM (\d+\.\d+)/
  
  attr_reader :earthquakes
  
  def initialize
    @earthquakes = []
    fetch_earthquakes
  end
  
  def fetch_earthquakes
    xml = File.read('data/quakes.xml') if File.exists?('data/quakes.xml')
    xml = open(SOURCES[:quakes]).read unless xml
    doc = Hpricot xml
    
    (doc / 'entry').each do |entry|
      point = (entry / 'georss:point').inner_html.split(' ').map {|n| n.to_f }
      mag = (entry / 'title').inner_html.match(MAGNITUDE_FINDER)[1].to_f
      # Faux Richter-scale adjustments to visual magnitude size.
      mag = (1.85 ** mag) / 3.6 + 1.5
      @earthquakes << Location.new(point[0], point[1], mag)
    end
  end
  
  
end