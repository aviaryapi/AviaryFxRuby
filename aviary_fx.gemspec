require 'rubygems'
SPEC = Gem::Specification.new do |s|
  s.name = "aviary_fx"
  s.version = "1.0.0"
  s.author = "Aviary"
  s.email = "support@aviary.com"
  s.summary = "A Ruby API wrapper for the AviaryFX API."
  s.description = "A Ruby API wrapper for the AviaryFX API as well as classes representing various Aviary objects."
  s.files = "lib/aviary_fx.rb"
  s.has_rdoc = true
  s.add_dependency "json"
  s.add_dependency "nokogiri", ">= 1.4"
  s.add_dependency "rest-client"
end
