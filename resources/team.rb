require 'set'

property :name, [String, Symbol], required: true, name_property: true
property :org, [String, Symbol], required: true
property :description, String, required: false
property :privacy, [:secret, :closed], default: :secret

usernames = {
  "should be list of usernames" => lambda do |names|
    names.all? { |name| name.is_a?(String) }
  end
}

property :maintainers, Array, required: false, default: [], callbacks: usernames
property :members, Array, required: false, default: [], callbacks: usernames

repos = {
  "should be list of repos" => lambda do |names|
    names.all? { |name| name.is_a?(String) }
  end
}

property :pull_repos, Array, required: false, default: [], callbacks: repos
property :push_repos, Array, required: false, default: [], callbacks: repos
property :admin_repos, Array, required: false, default: [], callbacks: repos

def all_expected_users
  (maintainers + members).to_set
end

def all_expected_repos
  (admin_repos + push_repos + pull_repos).to_set
end

include GithubCookbook::Helpers
include GithubCookbook::ConvergeBy
include Chef::DSL::Recipe::FullDSL

action :create do
  if current_team && !changes.empty?
    converge_by "Updating team #{name} #{changes.inspect}" do
      github.update_team(id, changes)
    end
  elsif !current_team
    converge_by "Creating team #{name} #{team_hash.inspect}" do
      @current_team = github.create_team(org, team_hash.merge(name: name))
    end
  end
  sync_all_members
  sync_all_repos
end

def sync_all_members
  remove_members(all_current_members - all_expected_users)
  add_members(:maintainer, maintainers.to_set - current_maintainers)
  add_members(:member, members.to_set - current_members)
end

def remove_members(users)
  return if users.empty?
  users.each do |user|
    converge_by "Removing user #{user} from team #{name}" do
      github.remove_team_member id, user
    end
  end
end

def add_members(type, users)
  return if users.empty?
  skip_pending_members(users, type).each do |user|
    converge_by "Adding user #{user} to team #{name} as #{type}" do
      github.add_team_membership id, user, role: type
    end
  end
end

def skip_pending_members(users, type)
  users.reject do |user|
    pending = membership_pending?(user, type)
    if pending
      log "Membership pending for user #{user} to team #{name} as #{type}" do
        level :warn
      end
    end
    pending
  end
end

def sync_all_repos
  remove_repos(all_current_repos - all_expected_repos)
  add_repos(:admin, repos_to_add(:admin))
  add_repos(:push, repos_to_add(:push))
  add_repos(:pull, repos_to_add(:pull))
end

def remove_repos(repos)
  return if repos.empty?
  repos.each do |repo|
    converge_by "Removing repo #{repo} from team #{name}" do
      github.remove_team_repository id, "#{org}/#{repo}"
    end
  end
end

def add_repos(type, repos)
  return if repos.empty?
  repos.each do |repo|
    converge_by "Adding repo #{repo} to team #{name} as #{type}" do
      github.add_team_repository id, "#{org}/#{repo}", permission: type
    end
  end
end

def repos_to_add(type)
  send("#{type}_repos").to_set - current_repos(type)
end

def team_hash
  {
    privacy: privacy.to_s,
    description: description
  }
end

def changes
  team_hash.select { |k, v| v != current_team[k] }
end

def all_current_members
  current_maintainers + current_members
end

def all_current_repos
  team_repos.map { |m| m[:name] }.to_set
end

def current_maintainers
  @current_maintainers ||= get_members(:maintainer)
end

def current_members
  @current_members ||= get_members(:member)
end

def current_repos(type)
  team_repos.select { |r| r[:permission] == type }.map { |m| m[:name] }.to_set
end

def id
  current_team.id
end

def current_team
  @current_team ||= begin
    github.org_teams(org).find { |t| t['name'] == name }
  rescue ::Octokit::NotFound
    nil
  end
end

def get_members(type)
  github.team_members(id, role: type).map { |m| m[:login] }.to_set
end

def membership_pending?(user, type)
  membership = github.team_membership(id, user)
  membership[:state] == 'pending' && membership[:role] == type.to_s
rescue Octokit::NotFound
  false
end

def team_repos
  @team_repos ||= github.team_repositories(id).map do |repo|
    { name: repo[:name], permission: permission_for(repo[:permissions]) }
  end
end

def permission_for(permissions)
  if permissions[:admin]
    :admin
  elsif permissions[:push]
    :push
  elsif permissions[:pull]
    :pull
  end
end
