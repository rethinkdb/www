# Directories and files generated by this Rakefile
#   - _includes: Used for Jekyll includes. Created by merging the
#                _jekyll/_includes directories of the www + docs repos
#   - assets/images/docs: Used for images from the docs repo.
$generated_files = [
    '_includes',
    'assets/images/docs',
    '_data/docs',
]

# Configuration details for external repos (e.g. docs)
$external_repos = [
    {
        "repo" => "docs",
        "destination" => "docs",
        "branch" => "master"
    },
]

# ---- Rake tasks

task :default => :serve

desc 'Set up the build environment'
task :init do
    # Install packages
    sh 'bundle config --local build.therubyracer --with-v8-dir=$(brew --prefix v8)'
    sh 'bundle install'

    # Clone the external repos
    root = pwd
    $external_repos.map{ |repo|
        clone_repo(root, repo)
    }
end

desc 'Clean up the generated site'
task :clean do
    rm_rf '_site'
    rm_rf '_deploy'
    rm '.jekyll-metadata', :force => true
    $generated_files.each{ |d|
        rm_rf d
    }
end

desc 'Pull the latest commits for the external repos'
task :pull do
    # Make sure we've checked out the right branch
    root = pwd
    $external_repos.map{ |repo|
        begin
            cd "#{root}/#{repo["destination"]}"
            pull_branch("#{repo["branch"]}") 
        rescue
            $stderr.puts "Error when trying to pull #{repo["repo"]}. Did you forget to run `rake init_subs`?"
            exit 1
        end
    }

    cd root
end

# Merges assets from the www repo and the docs repo
desc 'Copy assets and includes from the docs repository'
task :copy_assets do
    # Create each destination directory, if it doesn't already exist
    ['_includes'].each{ |dir_name|
        FileUtils.mkdir_p(dir_name) unless Dir.exist?(dir_name)
    }

    assets_to_copy = [
        {:source => '_jekyll/_includes/.', :target => '_includes/'},
        {:source => 'docs/_jekyll/_includes/.', :target => '_includes/docs/'},
        {:source => 'docs/_jekyll/_images/.', :target => 'assets/images/docs/'},
        {:source => 'docs/_jekyll/_data/.', :target => '_data/docs/'},
    ]
    assets_to_copy.each{ |asset|
        FileUtils.cp_r(asset[:source], asset[:target], :verbose => true)
    }
end

desc 'Build site with Jekyll'
task :build => ['clean', 'copy_assets'] do
    jekyll('build')
end

desc 'Start server and regenerate files on change'
task :serve => ['copy_assets'] do
    check_for_required_files(:warning => true)
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

desc 'Build site with Jekyll'
task :generate => ['build'] do
end


# ---- Rake functions

# Run Jekyll
def jekyll(opts = '')
    if ENV['dev']=='on'
        dev = ' --plugins=_plugins,_plugins-dev'
    else
        dev = ''
    end
    sh "bundle exec jekyll #{opts}#{dev} --trace"
end

# Check if all generated files are present: by default abort if files aren't present, otherwise show a warning
def check_for_required_files(opts={})
    missing_files = 0
    $generated_files.each do |f|
        if !File.exist?(f)
            puts "Required file missing: #{f}"
            missing_files +=1
        end
    end
    if missing_files > 0
        error = "#{missing_files} required files not found. Run `rake build` before deploying."
        if opts[:warning] then puts error else fail error end
    end
end

def pull_branch(branch_name)
    sh "git checkout #{branch_name}"
    sh "git pull"
end

# Git: clone a RethinkDB GitHub repository
def clone_repo(root, repo)
    begin 
        destination = "#{root}/#{repo["destination"]}"
        rm_rf destination
        sh "git clone https://github.com/rethinkdb/#{repo["repo"]}.git #{destination}"
        cd destination
        sh "git checkout #{repo["branch"]}"
    rescue Exception
        $stderr.puts "Error while cloning #{repo["repo"]}"
        exit 1
    end
end
