#JonBardin

class Location

  BASE_URL = "http://where.yahooapis.com/v1/"

  def self.search (query)
    places = []
    url = BASE_URL + "places.q('" + URI.encode(query) + "')?appid=" + APP_ID 
    xml = Fast.fetch(url)
    doc = REXML::Document.new(xml)
    doc.elements.each("/places/place") { |place|
      places << place
    }
    return places
  end

  def self.neighbors (woeid)
    places = []
    url = BASE_URL + "place/#{woeid}/neighbors?appid=" + APP_ID

    xml = Fast.fetch(url)
    doc = REXML::Document.new(xml)
    doc.elements.each("/places/place") { |place|
      places << place unless place.elements["name"].text.to_i.to_s == place.elements["name"].text
    }
    return places
  end

end
