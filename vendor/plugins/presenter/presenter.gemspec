Gem::Specification.new do |spec|
  spec.name           = 'presenter'
  spec.version        = '0.1.0'
  spec.author         = 'Rails Presenter'
  spec.email          = 'assaf@labnotes.org'
  spec.homepage       = "http://github.com/assaf/#{spec.name}"
  spec.summary        = "Add later ..." # TODO

  spec.files          = Dir['lib/**/*', 'rails/**/*', 'README', 'CHANGELOG', 'MIT-LICENSE', 
                            '*.gemspec', 'Rakefile', 'spec/**/*', 'doc/**/*']
  spec.require_paths  = 'lib'

  spec.has_rdoc           = true
  spec.extra_rdoc_files   = 'README', 'CHANGELOG', 'MIT-LICENSE'
  spec.rdoc_options       = '--title', spec.name,
                            '--main', 'README', '--line-numbers', '--inline-source',
                            '--webcvs', "#{spec.homepage}/tree/master"
  spec.rubyforge_project  = spec.name

  # Tested against these dependencies.
  spec.add_dependency 'rails'
end
