RethinkDB website
===

## Building the website

__Note:__ Before you can build the website, make sure your system is ready;
read the "Getting your system ready to build the website" section.

We use [Jekyll][] to build the website. To setup, build,
and deploy the website, you will use a series of `rake` tasks.

The website relies on an external repository ([rethinkdb/docs][]), which is
managed by the `rake` tasks.

[rethinkdb/docs]: https://github.com/rethinkdb/docs
[Jekyll]: http://jekyllrb.com/

### First-time setup

Start by cloning this repository:

```
git clone git@github.com:rethinkdb/www.git
```

Before you can build the site, you need to install required dependencies with
Bundler, and initialize external repositories:

```
rake init
```

### Build and serve the website

To build and serve the site:

```
rake
```

### Other operations

- `rake -T`: see the complete list of `rake` tasks
- `rake up`: quickly serve the site (this skips the initial build)
- `rake pull`: update external `git` repositories
- `rake build`: builds the website (outputs to `_site`)
- `rake clean`: remove all generated directories and reset the site
- `rake serve`: serve the development locally **with** hot reloading
- `rake pyserve`: serve the development locally with python **without** hot reloading

## Getting your system ready to build the website

This guide steps through how to build the website, assuming you have no tools installed. It describes:

- Setting up Homebrew
- Installing Node.js / `nvm`
- Installing Ruby / `rbenv` / Bundler

Remember: if you update your path at any point in this guide, start a new Bash
sesion or run (on OS X):
```
source ~/.bash_profile
```

Set up Homebrew
```
ruby <(curl -fsS https://raw.githubusercontent.com/Homebrew/install/master/install)
```

Append this to your path to use binaries installed by Homebrew:
```
export PATH="/usr/local/bin:$PATH"
```

Update Homebrew formulae:
```
brew update
```

Install `nvm` to manage Node.js version (using v0.39.7 in this case):
```
curl https://raw.githubusercontent.com/creationix/nvm/v0.39.7/install.sh | bash
```

Tell `nvm` to install the latest LTS version of Node.js (in this case, 18)
```
nvm install 18
```

Set the default version of Node.js:
```
nvm alias default 18
```

Install `rbenv` to manage Ruby versions:
```
brew install rbenv ruby-build v8
```

*Add this to your path:* Uses Homebrew's directories rather than `~/.rbenv`:
```
export RBENV_ROOT=~/.rbenv
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
```

*Add this to your path:* enable shims and autocompletions for `rbenv`:
```
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
```

Install the latest version of Ruby 2.7.x (in this case, 2.7.8)
```
rbenv install -s 2.7.8
```

Set the Ruby version to be the global default
```
rbenv global 2.7.8
rbenv rehash
```

Update to the latest verion of Rubygems:
```
gem update --system
```

Install Bundler:
```
gem install bundler
```

Configure Bundler for faster, paralleized gem installation. First, find out the number of cores on your system (on OS X):
```
sysctl -n hw.ncpu
```

Then, configure Bundler to use `n-1` cores, where `n` is the number of cores on your system (in this case, 4 cores):
```
bundle config --global jobs 3
```

Now, ensure you're in the root directory of the git repo and run:
```
rake init
```

You can test that everything was successful by trying to build the site:
```
rake serve
```

# Deploying

We are automatically deploying to Netlify. This means, whenever a pull request is merged, after the successulf build, the new version of the site will be available.

*Note: A preview site will be generated for every pull request.*
