require 'rubygems'
require 'rake'
require '/var/www/siffd/siffd'
require '/var/www/siffd/boot'
 
desc "Default Task"
task :default => [ :migrate ]

desc "Migrate"
task :migrate do
  puts "migrating..."
  Siffd::Models.create_schema
end

desc "Categories"
task :categories do
  puts "categories"
  Upcoming.categories.each { |category|
    puts category.attributes["name"]
    puts "\t" + category.attributes["description"]
  }
end
