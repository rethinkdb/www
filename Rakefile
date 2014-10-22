task :default => :serve

desc 'Set up the build environment.'
task :init do
    sh 'bundle install'
end

desc 'Clean up generated site'
task :clean do
    rm_rf '_site'
    rm_rf '_deploy'
end

desc 'Build site with Jekyll'
task :build => ['clean'] do
    jekyll('build')
end

desc 'Start server and regenerate files on change'
task :serve do
    jekyll('serve') 
end

desc 'Start the server quickly, using an existing build, and regenerate files on change'
task :up do
    jekyll('serve --skip-initial-build')
end

desc 'Start Python SimpleHTTPServer'
task :pyserve do
    cd '_site'
    sh 'python -m SimpleHTTPServer 8888'
end

desc 'Benchmark the Jekyll build'
task :benchmark do
    require 'benchmark'
    time = Benchmark.realtime do
        Rake::Task[:build].invoke
    end
    puts "Time elapsed #{time*1000} milliseconds"
end


def jekyll(opts = '')
    if ENV['dev']=='on'
        dev = ' --plugins=_plugins,_plugins-dev'
    else
        dev = ''
    end
    sh "bundle exec jekyll #{opts}#{dev} --trace"
end
