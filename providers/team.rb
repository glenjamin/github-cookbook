use_inline_resources

def whyrun_supported?
  true
end

include GithubCookbook::Helpers

action :create do
  if current_team && !changes.empty?
    converge_by "Updating team #{new_resource.name} #{changes.inspect}" do
      github.update_team(current_team.id, changes)
    end
  elsif !current_team
    converge_by "Creating team #{new_resource.name} #{team_hash.inspect}" do
      github.create_team(
        new_resource.org,
        team_hash.merge(name: new_resource.name)
      )
    end
  end
end

def team_hash
  {
    privacy: new_resource.privacy.to_s
  }
end

def current_team
  @current_team ||= begin
    github.org_teams(new_resource.org).find do |t|
      t['name'] == new_resource.name
    end
  rescue Octokit::NotFound
    nil
  end
end

def changes
  team_hash.select { |k, v| v != current_team[k] }
end
