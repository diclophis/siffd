#JonBardin

class Yelp

  BASE_URL = "http://api.yelp.com/"

  def self.business_review_search_geo (lat, long, term = nil, radius = nil, num_biz_requested = nil)
    parameters = {}
    parameters[:ywsid] = YWSID
    parameters[:lat] = lat
    parameters[:long] = long
    parameters[:radius] = radius if radius
    parameters[:term] = term if term
    parameters[:num_biz_requested] = num_biz_requested if num_biz_requested

    query_string = 'business_review_search?' + parameters.map { |k,v|
      "%s=%s" % [URI.encode(k.to_s), URI.encode(v.to_s)]
    }.join('&')

    url = BASE_URL + query_string

Camping::Models::Base.logger.debug(url)

    open(url) { |json|
      response = ActiveSupport::JSON.decode(json.readlines.join)
      return businesses = response["businesses"]
    }
  end
end
