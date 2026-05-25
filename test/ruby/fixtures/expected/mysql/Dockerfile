ARG PMRAILS_RUBY_VERSION
ARG PMRAILS_RUBY_VERSION_SUFFIX=""
FROM ruby:${PMRAILS_RUBY_VERSION}${PMRAILS_RUBY_VERSION_SUFFIX}

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      # MySQL / MariaDB
      default-libmysqlclient-dev default-mysql-client \
      # For Node.js installation
      curl \
      # Timezone data
      tzdata \
      # For long output in Rails console
      less \
      # For mimemagic gem
      shared-mime-info \
      # For image_processing gem
      libvips \
      # For mini_magick gem
      # imagemagick \
    && rm -rf /var/lib/apt/lists/*

ARG NODE_MAJOR=24
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*
