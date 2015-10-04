module GithubCookbook
  module Helpers
    def load_current_resource
      require 'octokit'
    rescue
      chef_gem 'octokit' do
        compile_time true
      end
      require 'octokit'
    end

    def github
      @github ||= ::Octokit::Client.new(
        access_token: node['github']['token'],
        auto_paginate: true
      ).tap do |github|
        github.default_media_type =
          'application/vnd.github.ironman-preview+json'
      end
    end
  end
end
