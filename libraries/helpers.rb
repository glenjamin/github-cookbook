module GithubCookbook
  module Helpers
    def load_current_resource
      chef_gem 'octokit' do
        compile_time true
      end
    end

    def github
      require 'octokit'
      @github ||= ::Octokit::Client.new(
        access_token: node['github']['token'],
        auto_paginate: true
      )
    end
  end
end
