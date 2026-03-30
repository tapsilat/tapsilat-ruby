FROM ruby:3.2-slim

# Install dependencies for gems
RUN apt-get update -qq && apt-get install -y build-essential

WORKDIR /app

# Install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy source code
COPY . .

# Default command
CMD ["bundle", "exec", "rspec"]
