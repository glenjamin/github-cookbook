use_inline_resources

def whyrun_supported?
  true
end

include GithubCookbook::Helpers

action :create do
  if current_repo && !changes.empty?
    converge_by "Updating repo #{new_resource.slug} #{changes.inspect}" do
      github.edit_repository(new_resource.slug, changes)
    end
  elsif !current_repo
    converge_by "Creating repo #{new_resource.slug} #{repo_hash.inspect}" do
      github.create_repository(
        new_resource.name,
        repo_hash.merge(organization: new_resource.org)
      )
    end
  end
end

def repo_hash
  {
    private: new_resource.private_repo,
    description: new_resource.description,
    homepage: new_resource.homepage,
    has_issues: new_resource.issues,
    has_wiki: new_resource.wiki,
    has_downloads: new_resource.downloads
  }
end

def current_repo
  @current_repo ||= begin
    github.repository(new_resource.slug)
  rescue Octokit::NotFound
    nil
  end
end

def changes
  repo_hash.select { |k, v| v != current_repo[k] }
end
