source "https://rubygems.org"

gem "fastlane", :github => "keeshux/fastlane", :ref => "775406fc38ea41b627e9f1bc2f07314f2df8cf4c"
gem "dotenv"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
