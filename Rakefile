deploy_config = '_deploy-config.yml'
algolia_root = '_algolia-build'

task :default => :serve

desc 'Set up the build environment.'
task :init do
    sh 'bundle install'
end

desc 'Clean up generated site'
task :clean do
    rm_rf '_site'
    rm_rf '_deploy'
    rm_rf algolia_root
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
                        language: header['languge'],
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
    #jekyll('build -d ' + algolia_root)
    
    # Fetch the article content and strip the HTML for each article
    docs_processed = 0
    index.each_with_index do |(title, article_set), i|
        article_set.each do |article|
            # Check if the file exists
            path = algolia_root + '/' + article[:path]
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

    require 'rubygems'
    require 'algoliasearch'

    deploy_config = YAML.load_file(deploy_config)

    puts "\nUploading index to Algolia..."
    Algolia.init :application_id => deploy_config['algolia']['application_id'], :api_key => deploy_config['algolia']['api_key']
    algolia_index = Algolia::Index.new('docs')
    algolia_index.clear_index
    algolia_index.add_objects(index)
    puts "Done."
end

def jekyll(opts = '')
    if ENV['dev']=='on'
        dev = ' --plugins=_plugins,_plugins-dev'
    else
        dev = ''
    end
    sh "bundle exec jekyll #{opts}#{dev} --trace"
end
