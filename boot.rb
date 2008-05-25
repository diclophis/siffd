#JonBardin

$appver = '0.1'
$appname = 'dixie'
$appid = "#{$appname} v#{$appver}"
$apphost = '[127.0.0.1]'

Camping::Models::Base.establish_connection(
  :adapter => :mysql,
  :database => "siffd",
  :username => "root",
  :password => "qwerty",
  :host => "localhost",
  :socket => "/var/run/mysqld/mysqld.sock"
)

Siffd::Models.create_schema

#Camping::Models::Base.observers = Dixie::Models::CacheObserver 
#Camping::Models::Base.instantiate_observers
Camping::Models::Base.logger = Logger.new('/var/log/siffd.log')

#RisingCode::Models::User.realm = "risingcode.com" 

ENV['PATH'] = '/usr/bin'
ENV['COMP_ROOT'] = '/var/www/siffd'

require '/var/www/siffd/monkey_patches'
