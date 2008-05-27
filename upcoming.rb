#JonBardin

class Upcoming

  BASE_URL = "http://upcoming.yahooapis.com/services/rest/"

  def self.popular
    events = []
    cities = []
    url = "http://upcoming.yahoo.com/popular/"
    open(url) { |html|
      doc = Hpricot(html)
      doc.search("table tr td a").collect { |a|
        if a[:href].include?("event") then
          events << a.inner_text
        elsif a[:href].include?("place") then
          cities << a.inner_text unless a.inner_text.blank?
        end
      }
      return events.uniq, cities.uniq
    }
  end

  def self.metro_search (search_text)
    metros = []
    parameters = {}
    parameters[:api_key] = API_KEY
    parameters[:method] = "metro.search"
    parameters[:search_text] = search_text

    query_string = '?' + parameters.map { |k,v|
      "%s=%s" % [URI.encode(k.to_s), URI.encode(v.to_s)]
    }.join('&')

    url = BASE_URL + query_string

    open(url) { |xml|
      doc = REXML::Document.new(xml)
      doc.elements.each("/rsp/metro") { |metro|
        metros << metro
      }
    }
    return metros 
  end

  def self.text_search (search_text, location = nil)
    events = []
    parameters = {}
    parameters[:api_key] = API_KEY
    parameters[:method] = "event.search"
    parameters[:search_text] = search_text unless search_text.blank?
    parameters[:location] = location if location

    query_string = '?' + parameters.map { |k,v|
      "%s=%s" % [URI.encode(k.to_s), URI.encode(v.to_s)]
    }.join('&')

    url = BASE_URL + query_string

Camping::Models::Base.logger.debug(url)

    open(url) { |xml|
      doc = REXML::Document.new(xml)
      doc.elements.each("/rsp/event") { |event|
        events << event
      }
    }
    return events 
  end

end
