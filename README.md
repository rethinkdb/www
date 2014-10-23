RethinkDB website
===


## Building the website

You must have the following tools available on your system:

- Ruby
- Bundler
- Node.js

Install the necessary gems:
```
bundle install
```

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

Install `nvm` to manage Node.js version (using v0.17.3 in this case):
```
curl https://raw.githubusercontent.com/creationix/nvm/v0.17.3/install.sh | bash
```

Tell `nvm` to install the latest version of Node.js (in this case, 0.10)
```
nvm install 0.10
```

Set the default version of Node.js:
```
nvm alias default 0.10
```

Install `rbenv` to manage Ruby versions:
```
brew install rbenv ruby-build
```

*Add this to your path:* Uses Homebrew's directories rather than `~/.rbenv`:
```
export RBENV_ROOT=~/.rbenv
```

*Add this to your path:* enable shims and autocompletions for `rbenv`:
```
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
```

Install the latest version of Ruby (in this case, 2.1.3)
```
rbenv install -s 2.1.3
```

Set the Ruby version to be the global default
```
rbenv global 2.1.3
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
