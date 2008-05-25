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
=begin
  class CreatePeople < V(2)
    def self.up
      create_table :people, :force => true do |t|
        t.column :identity_url,  :text
        t.column :display_identifier, :text

        t.column :name, :text
        t.column :email, :text
        t.column :nickname, :text
        t.column :phone, :text
        t.column :image_id, :string, :null => false

        t.column :created_at, :datetime, :null => false
        t.column :updated_at, :datetime, :null => false
      end
    end
    def self.down
      drop_table :people
    end
  end
=end
end

module Siffd::Controllers
  class Login < R("/dashboard/login(.*)")
    include Camping::Session
    def get(*args)
=begin
      begin
        if (@input.has_key?("openid.mode")) then
          user = User.find_by_openid_url!(@state, @input, R(Login, nil))
          @state.user_id = user.id
          return redirect(R(Dashboard))
        else
          raise "Login Required"
        end
      rescue Exception => e
        @login_exception = e
        other_layout {
          render :login 
        }
      end
=end
    end
    def post(*args)
=begin
      begin
        new_state, authorized_action_url = User.get_authorized_action_url(@input.openid_url, R(Login, nil))
        @state = new_state
        redirect(authorized_action_url)
      rescue Exception => e
        @login_exception = e
        other_layout {
          render :login
        }
      end
=end
    end
  end

  class Logout < R("/dashboard/logout")
    def get
      redirect R(Index)
    end
  end

  class Index < R('/', '/search/(\d+)/(\d+)/(\d+)', '/search/(.*)')
    def get(*args)
      @popular_events, @popular_cities = Upcoming.popular
      @new_places = FortyThreePlaces.new_places 

      @search = nil
      @date = nil

      case args.length
        when 1
          @search = args.first

        when 3
          @date = args.join("/")

      end

      if @search.nil? then
        if @input.search.blank? then
          @search = remote_location[:name]
        else
          @search = @input.search
        end
      end

      if @date.nil? then
        if @input.date.blank? then
          @date = today.slugify.join("/")
        else
          @date = @input.date
        end
      end

      render :index
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
        form(:action => R(Login, nil)) {
          input.identity_url!(:name => :identity_url)
        } unless authenticated
        form(:action => R(Index)) {
          ul.dates! {
            li {
              img.calendar!(:src => "/images/calendar.png", :alt => "select date")
            }
            li {
              input.date!(:name => :date, :value => @date)
            }
            li {
              a(:href => R(Index, *today.slugify)) {
                "today"
              }
            }
            li {
              a(:href => R(Index, *tomorrow.slugify)) {
                "tomorrow"
              }
            }
            li {
              a(:href => R(Index, *this_friday.slugify)) {
                "this friday"
              }
            }
            li {
              a(:href => R(Index, *next_friday.slugify)) {
                "next friday"
              }
            }
          }
          div.header! {
            h1 {
              a(:href => R(Index)) {
                "Siffd"
              }
              text(" your daily colandar of events")
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
            a(:href => R(Index, city)) {
              city
            }
          }
        }
      }
      ul.popular_events! {
        @popular_events.each { |event|
          li {
            a(:href => R(Index, event)) {
              event
            }
          }
        }
      }
      ul.new_places! {
        @new_places.each { |place|
          li {
            a(:href => R(Index, place)) {
              place
            }
          }
        }
      }
      div.search! {
        input(:name => :search, :value => @search)
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
