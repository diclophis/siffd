#JonBardin

class Location

  BASE_URL = "http://where.yahooapis.com/v1/"

  def self.search (query)
    places = []
    url = BASE_URL + "places.q('" + URI.encode(query) + "')"
    open(url) { |xml|
      doc = REXML::Document.new(xml)
      doc.elements.each("/places/place") { |place|
        places << place
      }
    }
    return places
  end

  def self.neighbors (woeid)
    places = []
    url = BASE_URL + "place/#{woeid}/neighbors"

Camping::Models::Base.logger.debug(url)

    open(url) { |xml|
      doc = REXML::Document.new(xml)
      doc.elements.each("/places/place") { |place|
        places << place
      }
    }
    return places
  end

end
