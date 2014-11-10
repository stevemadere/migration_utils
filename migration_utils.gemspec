# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name = 'migration_utils'
  s.summary = 'Utilities for complex activerecord migrations'
  s.email = 'steve@stevemadere.com'
  s.homepage = 'https://github.com/stevemadere/migration_utils'
  s.license = 'MIT'
  s.version = '0.0.2'
  s.authors = 'Steve Madere'
  s.files = Dir.glob('{lib}/**/*')
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.8.7'
  s.add_dependency 'rails'
end
