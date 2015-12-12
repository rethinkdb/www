require 'yaml'

# Load configuration
begin
    $config = YAML.load_file('_deploy-config.yml')
rescue Exception
    puts "Missing or incorrect configuration."
    exit 1
end

$algolia_root = '_algolia-build'

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
    rm_rf $algolia_root
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
        FileUtils.mkdir_p(dir_name) unless Dir.exists?(dir_name)
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

#This is the first Ruby code @dalanmiller has ever written
# this process is also lossy by default with PNGs. 
desc 'Optimize image directories'
task :imgoptimize do
    sh "pngquant -s 1 --ext .png -f assets/images/**/*.png"
end

desc 'Build and deploy to a remote server'
task :deploy do
    changes = `git diff --exit-code > /dev/null; echo $?`
    if changes.to_i == 1
        $stderr.puts "Commit your changes before deploying the site."
        exit 1
    end

    # Build a clean deployment site
    out_dir = '_site'
    Rake::Task['pull'].invoke
    Rake::Task['clean'].invoke
    Rake::Task['build'].invoke

    # Copy the files over with rsync
    src = File.join(Dir.pwd, out_dir)
    host = $config['web']['host']
    dest = "#{host}:#{$config['web']['directory']}"

    # Rsync options
    rsync = {
        :flags => '-Prvzh --delete',
        :chmod => '--chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r', # 744 for directories, 644 for files
        :ssh   => "-e 'ssh -p #{$config['web']['port']}'", # ssh command for deployment
    }
    puts "Source: #{src} | Destination: #{dest}"

    sh "rsync #{rsync[:flags]} #{rsync[:chmod]} #{rsync[:ssh]} #{src}/ #{dest}"
    puts 'Site published to Linode.'
end 

desc 'Update the nginx configuration'
task :update_nginx do
    #host = $config['web']['host']
    #dest = "#{host}:#{$config['web']['directory']}"    -- dest is public_html, so this needs to be refactored TODO
    #port = $config['web']['port']
    #nginx_conf = "_nginx/nginx.conf"
    #sh "scp -P #{port} #{nginx_conf} #{dest}"
end

# TODO -- nokogiri portion needs to be rewritten, since the DOM has been rearchitected for docs
desc 'Build Algolia search data'
task :algolia do
    require 'yaml'
    require 'nokogiri'

    # Figure out which files to index, and where they'll be after Jekyll generates them
    index = {}
    to_index = ['docs']
    exclude_from_index = [
        'docs/api/deprecated/1.12.md',
        'docs/api/deprecated/1.13.md',
        'docs/api/javascript/index.md',
        'docs/api/python/index.md',
        'docs/api/ruby/index.md',
    ]

    puts "Adding documents to index...."
    total_docs = 0
    to_index.each do |dir|
        Dir.glob(dir + '/**/*.{md,html}') do |f|
            # If the file is in the excluded list, don't index it
            next if exclude_from_index.include? f

            # Open the file and read its YAML headers
            contents = File.open(f, 'rb') { |f| f.read }
            if (yaml_file = contents.match(/^(?<header>---\s*\n.*?\n?)^(---\s*$\n?)/m))
                header = YAML.load(yaml_file[:header])

                # If this article is an API command, use the command as the title
                if header['command']
                    header['title'] = header['command']
                end
                
                # Only process articles with titles
                if header['title']
                    # If the article hasn't been indexed yet, initialize a list of articles with that title
                    index[header['title']] ||= []
                    article = {
                        file: f,
                        title: header['title'],
                        language: header['language'],
                        permalink: header['permalink'],
                        layout: header['layout'],
                    }
                    # Use the permalink to determine the output path after Jekyll finished processing
                    if article[:permalink]
                        article[:path] = article[:permalink] + 'index.html'
                    # If no permalink was specified, look for an HTML file with the same name
                    else
                        article[:path] = article[:file].sub(/.[^.]+\z/,'.html')
                    end
                    # Add details on this article to the index
                    index[header['title']] << article
                    total_docs += 1
                end
            end
        end
    end

    puts "Indexed #{total_docs} documents."
    puts "Building documents with Jekyll..."

    # Build the files using Jekyll
    jekyll('build -d ' + $algolia_root)
    
    # Fetch the article content and strip the HTML for each article
    docs_processed = 0
    index.each_with_index do |(title, article_set), i|
        article_set.each do |article|
            # Check if the file exists
            path = $algolia_root + '/' + article[:path]
            if not File.exist?(path)
                puts "Article not found:\n\t * Expected location: #{path}\n\t * Title: #{article[:title]}"
            # Otherwise, pull out the article content
            else
                article_content = File.open(path) { |f| Nokogiri::HTML(f) }
                case article[:layout]
                when 'documentation'
                    article_content = article_content.at_css('.documentation-content').text()
                when 'document'
                    article_content = article_content.at_css('.content').text()
                when 'api'
                    article_content = article_content.at_css('#api-sections').text()
                when 'example-app'
                    article_content = article_content.at_css('.example-app.section').text()
                when 'api-command'
                    article_content = article_content.at_css('#api-details')
                    article_content.search("#docs-switcher").remove()
                    article_content.search(".linksbox-container").remove()
                    article_content = article_content.text()
                else
                    article_content = ''
                    puts "Article could not be parsed, unknown layout:\n\t * Layout: #{article[:layout]}\n\t * Title: #{article[:title]}"
                end
                article[:content] = article_content
                docs_processed += 1
                STDOUT.write "\r#{docs_processed} / #{total_docs} documents processed."
            end
        end
    end

    index = index.values.flatten(1)


    # Deploy the index to Algolia
    require 'rubygems'
    require 'algoliasearch'

    deploy = YAML.load_file($deploy_config)

    puts "\nUploading index to Algolia..."
    Algolia.init :application_id => deploy['algolia']['app_id'], :api_key => deploy['algolia']['api_key']
    algolia_index = Algolia::Index.new('docs')
    algolia_index.clear_index
    algolia_index.add_objects(index)
    puts "Done."
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
        if !File.exists?(f)
            puts "Required file missing: #{f}"
            missing_files +=1
        end
    end
    if missing_files > 0
        error = "#{missing_files} required files not found. Run `rake build` before deploying."
        if opts[:warning] then puts error else fail error end
    end
end

# Git: checkout a branch
def checkout_branch(branch_name)
    sh "git checkout #{branch_name}"
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

# Git: hard reset to HEAD
def reset_repo(root, repo)
    sh "git reset HEAD --hard"
end
