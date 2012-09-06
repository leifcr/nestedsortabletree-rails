# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'nested_sortable_tree/rails/version'

Gem::Specification.new do |s|
  s.name        = 'nestedsortabletree-rails'
  s.version     = NestedSortableTree::Rails::VERSION
  s.summary     = 'Rails 3.2 integration for Jquery UI Nested Sortable Tree plugin.'
  s.description = 'Integrates jquery UI Nested Sortable Tree plugin into rails apps.'
  s.homepage    = 'https://github.com/leifcr/nestedsortabletree-rails'
  s.files       = Dir['README.md', 'LICENSE', 'Rakefile', 'lib/**/*', 'vendor/**/*']
  s.authors     = ['Leif Ringstad']
  s.email       = 'leifcr@gmail.com'

  s.add_dependency 'actionpack',  '~> 3.2.8'
  s.add_dependency 'jquery-rails',  '~> 2.1.1'

  s.add_development_dependency 'rake', '0.9.2'
end