Gem::Specification.new do |s|
  s.name = "knife-profitbricks-fog"
  s.version = "0.1"

  s.require_paths = ["lib"]
  s.authors = ["Christian Eichhorn"]
  s.date = "2015-03-15"
  s.description = "Knife Solo Client for Profitbricks cloud"
  s.email = ["c.eichhorn@webmasters.de"]
  s.extra_rdoc_files = ["README.md", "MIT-LICENSE"]
  s.files = []
  s.homepage = "https://github.com/webhoernchen/knife-profitbricks-fog"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.5"
  s.summary = "Knife Solo Client for Profitbricks cloud"
  
  s.add_runtime_dependency "fog-profitbricks"
  s.add_runtime_dependency "knife-solo"
  s.add_runtime_dependency "knife-solo_data_bag"
end
