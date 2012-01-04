# vim: set filetype=ruby et sw=2 ts=2:

require 'gem_hadar'

GemHadar do
  name        'bullshit'
  author      'Florian Frank'
  email       'flori@ping.de'
  homepage    "http://flori.github.com/#{name}"
  summary     'Benchmarking is Bullshit'
  description 'Library to benchmark ruby code and analyse the results'
  test_dir    'tests'
  ignore      '.*.sw[pon]', 'pkg', 'Gemfile.lock', 'data', 'coverage'
  readme      'README.rdoc'
  title       "#{name.camelize} -- Benchmarking in Ruby"
  executables  << 'bs_compare'

  dependency  'tins',      '~>0.3'
  dependency  'dslkit',    '~>0.2'
  dependency  'more_math', '~>0.0.2'
  clobber     'data/*.{dat,log}'

  install_library do
    libdir = CONFIG["sitelibdir"]
    install('lib/bullshit.rb', libdir, :mode => 0644)
    mkdir_p subdir = File.join(libdir, 'bullshit')
    for f in Dir['lib/bullshit/*.rb']
      install(f, subdir)
    end
    bindir = CONFIG["bindir"]
    install('bin/bs_compare', bindir, :mode => 0755)
  end
end
