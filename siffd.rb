#!/usr/bin/ruby

#JonBardin

require 'gserver'
require 'uri'
require 'ftools'
require 'rubygems'
require 'RMagick'
include Magick
require 'time'
require 'timeout'
require 'open3'
require 'open-uri'
require 'redcloth'
require 'digest/md5'
require 'daemons'
require 'benchmark'
require 'ruby2ruby'
require 'drb'
require 'uuidtools'
require 'right_aws'
require 'rexml/document'
require 'hpricot'

#import into the system
require 'camping'
require 'camping/fastcgi'
require 'camping/session'
require 'acts_as_versioned'
require 'action_mailer'
require 'tmail'
require 'openid'
require 'openid/store/filesystem'
require 'openid/consumer'
require 'openid/extensions/sreg'

require '/var/www/siffd/hostip'
require '/var/www/siffd/forty_three_places'
require '/var/www/siffd/upcoming'
require '/var/www/siffd/location'
require '/var/www/siffd/yelp'

Camping.goes :Siffd

module SessionSupport
  def self.included(base)
    base.class_eval do
      def self.include_session_support
        true
      end
    end
  end
end

module Siffd
  def service(*a)
    session = Camping::Models::Session.persist(@cookies)
    app = self.class.name.gsub(/^(\w+)::.+$/, '\1')
    @state = (session[app] ||= Camping::H[])
    hash_before = Marshal.dump(@state).hash
    s = super(*a)
    #if @method == "get" and @input.length == 0 and not @env['REQUEST_URI'].include?("dashboard") and not @env['REQUEST_URI'].include?("dangotalk") then
    #  cache_directory = "/tmp/cache/risingcode.com/#{@env['REQUEST_URI']}"
    #  File.makedirs(cache_directory)
    #  cache_filename = "#{cache_directory}/index.html"
    #  cache_file = File.new(cache_filename, "w")
    #  #cache_file.write(s.body)
    #  cache_file.close
    #end
    if session
      hash_after = Marshal.dump(@state).hash
      unless hash_before == hash_after
          session[app] = @state
          session.save
      end
    end
    return self
  end

  def authenticated
    @state.person_id
  end

  def nickname
Camping::Models::Base.logger.debug("4")
    unless @person
      @person = Models::Person.find(@state.person_id)
    end
Camping::Models::Base.logger.debug("5")
    @person[:nickname]
  end

  def today
    0.day.from_now
  end

  def tomorrow
    1.day.from_now
  end

  def this_friday
    (0..7).detect { |n|
      n.days.from_now.wday == 5
    }.days.from_now
  end

  def next_friday
    this_friday + 7.days
  end

  def remote_addr
    @env["REMOTE_ADDR"]
  end

  def remote_location
    Hostip.geolocate(remote_addr)
  end

end

module Siffd::Models
  class Base
    def Base.table_name_prefix
    end
  end
  class CreateSessions < V(1)
    def self.up
      create_table :sessions, :force => true do |t|
        t.column :hashid,      :string,  :limit => 32
        t.column :created_at,  :datetime
        t.column :ivars,       :text
      end
    end
    def self.down
      drop_table :sessions
    end
  end

  class CreatePeople < V(2)
    def self.up
      create_table :people, :force => true do |t|
        t.column :identity_url,  :text
        t.column :display_identifier, :text

        t.column :nickname, :text
        t.column :email, :text

        t.column :created_at, :datetime, :null => false
        t.column :updated_at, :datetime, :null => false
      end
    end
    def self.down
      drop_table :people
    end
  end

  class Person < Base
    @@realm = "siffd.com"
    validates_length_of :nickname, :within => 3..64
    validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
    validates_presence_of :nickname
    validates_presence_of :email
    validates_uniqueness_of :identity_url
    validates_uniqueness_of :nickname
    validates_uniqueness_of :email
    validates_format_of :nickname, :with => /^\w+$/ 

    def self.realm
      "http://" + @@realm
    end

    def self.realm=(realm)
      @@realm = realm
    end

    def self.get_authorized_action_url (openid_url, return_to_url, passthru = nil)
      @state_holder = Hash.new
      store = ::OpenID::Store::Filesystem.new("/tmp")
      openid_consumer = ::OpenID::Consumer.new(@state_holder, store)
      check_id_request = openid_consumer.begin(openid_url)
      openid_sreg = ::OpenID::SReg::Request.new(['nickname', 'email'])
      check_id_request.add_extension(openid_sreg)
      url = check_id_request.redirect_url(self.realm, self.realm + return_to_url)
      return [@state_holder, url]
    end
  end
end

module Siffd::Controllers
  class Login < R("/dashboard/login(.*)")
    include Camping::Session
    def get(*args)
      if (@input.has_key?("openid.mode")) then
        this_url = Person.realm + R(Login, nil)
        store = ::OpenID::Store::Filesystem.new("/tmp")
        openid_consumer = ::OpenID::Consumer.new(@state, store)
        openid_response = openid_consumer.complete(@input, this_url)
        if openid_response.status == :success then
          identity_url = openid_response.identity_url
          person = Person.find_by_identity_url(identity_url)
          unless person
            openid_sreg = ::OpenID::SReg::Response.from_success_response(openid_response)
            person = Person.new
            person.identity_url = identity_url
            person.display_identifier = openid_response.display_identifier
            person.identity_url = openid_response.identity_url
            person.nickname = openid_sreg["nickname"]
            person.email = openid_sreg["email"]
            person.save!
          end
          @state.person_id = person.id
          return redirect(R(Index))
        end
      end
    end
    def post(*args)
      @state, authorized_action_url = Person.get_authorized_action_url(@input.identity_url, R(Login, nil))
      redirect(authorized_action_url)
    end
  end

  class Logout < R("/dashboard/logout")
    def get
      @state.person_id = nil
      redirect(R(Index))
    end
  end

  class Index < R('/', '/(when)/(\d+)/(\d+)/(\d+)', '/(what)/(.*)', '/(where)/(.*)')
    def get(*args)
      @popular_events, @popular_cities = Upcoming.popular
      #@new_places = FortyThreePlaces.new_places 
      @new_places = [
        "Metropolitan Museum of Art",
        "Astrodome",
        "Paramount Theatre",
        "The Smithsonian",
        "Mile High Stadium",
        "The Louvre"
      ]

      @what = nil
      @when = nil
      @where = nil
      @location = nil
      @city_name = nil
      @state_name = nil
      @events = []
      @businesses = []
      @neighbors = []

      case args.shift
        when "when"
          @when = args.join("/")

        when "what"
          @what = args.join

        when "where"
          @where = args.join
      end

      unless @where then
        if @input.where.blank? then
          @where = remote_location[:name]
        else
          @where = @input.where
        end
      end

      unless @when then
        if @input.when.blank? then
          @when = today.slugify.join("/")
        else
          @when = Date.parse(@input.when).slugify.join("/")
        end
      end

      unless @what then
        @what = @input.what
      end

      @woeids = Location.search(@where)
      if @woeids.length > 0 then
        centroid = @woeids[0].elements["centroid"]
        latitude = centroid.elements["latitude"].text
        longitude = centroid.elements["longitude"].text
        @location  = "#{latitude},#{longitude}"
        @woeid = @woeids[0].elements["woeid"].text
        @city_name = @woeids[0].elements["admin2"].text
        @state_name = @woeids[0].elements["admin1"].text
        @businesses = Yelp.business_review_search_geo(latitude, longitude, @what)
        @neighbors = Location.neighbors(@woeid)
      else
        @metros = Upcoming.metro_search(@where)
        if @metros.length > 0 then
          @city_name = @metros[0].attributes["name"]
          @state_name = @metros[0].attributes["state_name"]
          @location = "#{city},#{state}"
        end 
      end

      @events = Upcoming.text_search(@what, @location)
    
      #@what = "Everything" if @what.blank?

      render :index
    end
    def post (*args)
      get(*args)
    end
  end

  class Dashboard < R("/dashboard")
    include SessionSupport
    def get
      render :dashboard 
    end
  end

end

module Siffd::Views
  def layout
    xhtml_transitional {
      head {
        title {
          "Siffd - Your Daily Colandar of Events"
        }
        link(:rel => "stylesheet", :type => "text/css", :href => "/stylesheets/calendar.css")
        link(:rel => "stylesheet", :type => "text/css", :href => "/stylesheets/main.css")
        script(:src => "/javascripts/prototype.js", :type => "text/javascript")
        script(:src => "/javascripts/scriptaculous.js", :type => "text/javascript")
        script(:src => "/javascripts/prototype.js", :type => "text/javascript")
        script(:src => "/javascripts/calendar.js", :type => "text/javascript")
        script(:src => "/javascripts/application.js", :type => "text/javascript")
        meta(:name => "viewport", :content => "width=850")
      }
      body {
        if authenticated then
          ul.login! {
            li {
              text("Logged&nbsp;in&nbsp;as:&nbsp;")
              nickname
            }
          }
        else
          form(:action => R(Login, nil), :method => :post) {
            ul.login! {
              li {
                input.identity_url!(:name => :identity_url)
              }
              li {
                input(:type => :submit, :value => "login")
              }
            }
          }
        end
        form(:action => R(Index), :method => :post) {
          ul.dates! {
            li {
              img.calendar!(:src => "/images/calendar.png", :alt => "select date")
            }
            li {
              input.when!(:name => :when, :value => @when)
            }
            li {
              a(:href => R(Index, "when", *today.slugify)) {
                "today"
              }
            }
            li {
              a(:href => R(Index, "when", *tomorrow.slugify)) {
                "tomorrow"
              }
            }
            li {
              a(:href => R(Index, "when", *this_friday.slugify)) {
                "this friday"
              }
            }
            li {
              a(:href => R(Index, "when", *next_friday.slugify)) {
                "next friday"
              }
            }
          }
          div {
            self << yield
          }
        }
      }
    }
  end

  def index
    div {
      ul.popular_cities! {
        @popular_cities.each { |city|
          li {
            a(:href => R(Index, "where", city)) {
              city
            }
          }
        }
      }
      ul.popular_events! {
        @popular_events.each { |event|
          li {
            a(:href => R(Index, "what", event)) {
              event
            }
          }
        }
      }
      ul.new_places! {
        @new_places.each { |place|
          li {
            a(:href => R(Index, "where", place)) {
              place
            }
          }
        }
      }
      div.search! {
        input(:name => :what, :value => @what)
        text("&nbsp;near&nbsp;")
        input(:name => :where, :value => @where)
        text("&nbsp;")
        input(:type => :submit, :value => "siffd")
      }
      div.results! {
        h1 {
          if (@what) then
            text(@what)
          else
            text("Everything")
          end
          text("&nbsp;near&nbsp;")
          text(@city_name)
          text(",&nbsp;")
          text(@state_name)
        } if (@city_name and @state_name)
        ul.events! {
          @events.each { |event|
            li {
              a(:href => R(Index, "what", event.attributes["name"])) {
                event.attributes["name"]
              }
            }
          }
        }
        ul.businesses! {
          @businesses.each { |business|
            li {
              img(:src => business["photo_url"]) unless business["photo_url"].blank?
              a(:href => R(Index, "what", business["name"])) {
                text(business["name"])
              }
            }
          }
        }
        ul.neighbors! {
          @neighbors.each { |neighbor|
            li {
              a(:href => R(Index, "where", neighbor.elements["name"].text)) {
                text(neighbor.elements["name"].text)
              }
            }
          }
        }
      }
    }
  end

=begin
  def login
    form(:method => :post) {
      h1("login")
      h2 {
        @login_exception
      } if @login_exception
      ul {
        li {
          a(:href => R(OpenID), :target => :_blank) {
            "OpenID URL"
          }
        }
        li {
          input.openid_url!(:type => :text, :name => :openid_url)
        }
        li {
          input(:type => "submit", :value => "go")
        }
      }
    }
  end
=end

end

#FortyThreePlaces.latest
#puts Upcoming.popular.inspect
#require '/var/www/siffd/boot'
#puts Upcoming.metro_search("Caesars Head State Park").inspect

=begin
[]   range specificication (e.g., [a-z] means a letter in the range a to z)
\w  letter or digit; same as [0-9A-Za-z]
\W  neither letter or digit
\s  space character; same as [ \t\n\r\f]
\S  non-space character
\d  digit character; same as [0-9]
\D  non-digit character
\b  backspace (0x08) (only if in a range specification)
\b  word boundary (if not in a range specification)
\B  non-word boundary
*   zero or more repetitions of the preceding
+   one or more repetitions of the preceding
{m,n}   at least m and at most n repetitions of the preceding
?   at most one repetition of the preceding; same as {0,1}
|   either preceding or next expression may match
()  grouping
=end
