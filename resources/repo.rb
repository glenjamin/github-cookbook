property :name, [String, Symbol], required: true, name_property: true
property :org, [String, Symbol], required: true
property :private_repo, [TrueClass, FalseClass], required: true
property :description, String, required: false
property :homepage, String, required: false
property :issues, [TrueClass, FalseClass], required: false, default: false
property :wiki, [TrueClass, FalseClass], required: false, default: false
property :downloads, [TrueClass, FalseClass], required: false, default: true

def slug
  "#{org}/#{name}"
end

include GithubCookbook::Helpers

action :create do
  if current_repo && !changes.empty?
    converge_by "Updating repo #{slug} #{changes.inspect}" do
      github.edit_repository(slug, changes)
    end
  elsif !current_repo
    converge_by "Creating repo #{slug} #{repo_hash.inspect}" do
      github.create_repository(name, repo_hash.merge(organization: org))
    end
  end
end

def repo_hash
  {
    private: private_repo,
    description: description,
    homepage: homepage,
    has_issues: issues,
    has_wiki: wiki,
    has_downloads: downloads
  }
end

def current_repo
  @current_repo ||= begin
    github.repository(slug)
  rescue Octokit::NotFound
    nil
  end
end

def changes
  repo_hash.select { |k, v| v != current_repo[k] }
end
