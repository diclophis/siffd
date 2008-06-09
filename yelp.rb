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

    json = Fast.fetch(url)
    response = ActiveSupport::JSON.decode(json.readlines.join)
    return businesses = response["businesses"]
  end

  def categories
    categories = File.open("categories").readlines.join
    first_levels = categories.split("*").collect { |blob| blob.strip! }
    second_levels = []
    third_levels = []
    hash = {}
    second_hash = {}
    first_levels.each { |first_level|
      next if first_level.nil?
      second_levels = first_level.split("|").collect { |blob| blob.strip unless blob.nil? }
      next if second_levels.first.nil?
      hash[second_levels.first] = {}
      second_levels.each { |second_level|
        next if second_level.nil?
        third_levels = second_level.split("+").collect { |blob| blob.strip unless blob.nil? }
        next if third_levels.first.nil?
        unless third_levels.first == second_levels.first then
          hash[second_levels.first][third_levels.first] = [] 
        end
        third_levels.each { |third_level|
          next if third_level.nil?
          unless third_level == third_levels.first then
            hash[second_levels.first][third_levels.first] << third_level
          end
        }
      }
    }
    return hash
  end
end
