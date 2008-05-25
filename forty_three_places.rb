#JonBardin

class FortyThreePlaces
  def self.new_places
    places = []
    url = "http://www.43places.com/rss/goals/all"
    open(url) { |rss|
      doc = REXML::Document.new(rss)
      doc.elements.each("/rss/channel/item") { |item|
        places << item.elements["title"].text
      }
      return places
    }
  end
end
