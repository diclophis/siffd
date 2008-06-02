#JonBardin

class Hostip
  BASE_URI = 'http://api.hostip.info/?ip='
  HOST_IP_PATH = '/HostipLookupResultSet/gml:featureMember/Hostip'
  def self.geolocate (ip)
    url = BASE_URI + ip + "&position=true"
    xml = Fast.fetch(url)
    doc = REXML::Document.new(xml)
    ret_h = Hash.new('')
    ret_h[:name] = ""
    ret_h[:name] = doc.elements["#{HOST_IP_PATH}/gml:name"].text
    if ret_h[:name] == "(Unknown City?)" then
      ret_h[:name] = "San Francisco"
    end
    ret_h[:country_name] = doc.elements["#{HOST_IP_PATH}/countryName"].text
    ret_h[:country_abbrev] = doc.elements["#{HOST_IP_PATH}/countryAbbrev"].text
    coordinates = ''
    unless doc.elements["#{HOST_IP_PATH}/ipLocation/gml:PointProperty/gml:Point/gml:coordinates"].nil?
      coordinates = doc.elements["#{HOST_IP_PATH}/ipLocation/gml:PointProperty/gml:Point/gml:coordinates"].text
    end
    longitude, latitude = '', ''
    longitude, latitude = coordinates.split(',', 2) unless coordinates == ''
    ret_h[:longitude] = longitude
    ret_h[:latitude] = latitude
    return ret_h
  end
end
