# Starting with Utopic
FROM ubuntu:utopic

# Ensure UTF-8 encoding is the default
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install global dependencies
RUN apt-get update
RUN apt-get install -y ruby ruby-dev build-essential zlib1g-dev ca-certificates git
RUN gem install bundle rake

# Install local dependencies
RUN mkdir /website
ADD Gemfile Gemfile.lock /website/
RUN echo 'fail "The repo has not been correctly mounted. Please pass the -v .:/website option to docker run."' > /website/Rakefile
RUN cd /website && bundle install --jobs `nproc`

# Use these settings when launching a container
EXPOSE 8888
WORKDIR /website
