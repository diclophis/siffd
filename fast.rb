
module Fast
  def self.fetch(uri, *rest, &block)
Camping::Models::Base.logger.debug(uri)
    if Cache.enabled? and Cache::alive?
      begin
        response = Cache::get(uri.to_s)
      rescue
        response = false
      end
    end
    unless response
      response_a = open(uri, *rest, &block)
      response = response_a.read 
      Cache::set(uri.to_s, response) if Cache.alive?
    end
    StringIO.new(response)
  end
  
  class Cache
    # Cache is not enabled by default
    @cache_enabled = false
    
    class << self
      attr_writer :expiry, :host
      
      # Is the cache enabled?
      def enabled?
        @cache_enabled
      end
      
      # Enable caching
      def enable!
        @cache ||= MemCache.new(host, :namespace => "openuri")
        @cache_enabled = true
      end
      
      # Disable caching - all queries will be run directly 
      # using the standard OpenURI `open` method.
      def disable!
        @cache_enabled = false
      end

      def disabled?
        !@cache_enabled
      end
      
      def get(key)
        @cache.get(key)
      end
      
      def set(key, value)
        @cache.set(key, value, expiry)
      end
            
      # How long your caches will be kept for (in seconds)
      def expiry
        @expiry ||= 60 * 10
      end
      
      def alive?
        servers = @cache.instance_variable_get(:@servers) and servers.collect{|s| s.alive?}.include?(true)
      end
      
      def host
        @host ||= "localhost:11211"
      end
    end
  end
end
