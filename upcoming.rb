#JonBardin

class Upcoming

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

end
