RethinkDB website
===

## Getting your system ready to build the website

This guide steps through how to build the website, assuming you have no tools installed. It describes:

- Setting up Homebrew
- Installing Node.js / `nvm`
- Installing Ruby / `rbenv` / Bundler


Remember: if you update your path at any point in this guide, start a new Bash session, or run (on OS X):

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

Install `nvm` to manage Node.js version (using v0.17.3 in this case):

```
brew install nvm
```

Tell `nvm` to install the latest version of Node.js (in this case, 0.12):

```
nvm install 0.12
```

Set the default version of Node.js:

```
nvm alias default 0.12
```

Install `rbenv` to manage Ruby versions:

```
brew install rbenv ruby-build
```


Add this to your path to use Homebrew's directories and enable shims/autocompletions for `rbenv`:

```
export RBENV_ROOT=/usr/local/var/rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
```

Install the latest version of Ruby (in this case, 2.2.1):

```
rbenv install -s 2.2.1
```

Set the Ruby version to be the global default:

```
rbenv global 2.2.1
rbenv rehash
```

(You can also set it to be the local default for this directory, although you will need to add `.ruby-version` to the `.git/info/exclude` file.)

Update to the latest verion of Rubygems:

```
gem update --system
```

Install Bundler:

```
gem install bundler
rbenv rehash
```

Configure Bundler for faster, paralleized gem installation. First, find out the number of cores on your system. On OS X, you can use:

```
sysctl -n hw.ncpu
```

Then, configure Bundler to use `n-1` cores, where `n` is the number of cores on your system (in this case, 4 cores):

```
bundle config --global jobs 3
```

## Building the website

Install the necessary gems:

```
bundle install
```

Build the web site and start the preview server:

```
rake
```

Visit `http://127.0.0.1:8888/` in your browser.