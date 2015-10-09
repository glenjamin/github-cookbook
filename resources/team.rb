require 'set'

usernames = {
  "should be list of usernames" => lambda do |names|
    names.all? { |name| name.is_a?(String) }
  end
}

property :name, [String, Symbol], required: true, name_property: true
property :org, [String, Symbol], required: true
property :description, String, required: false
property :privacy, [:secret, :closed], default: :secret
property :maintainers, Array, required: false, default: [], callbacks: usernames
property :members, Array, required: false, default: [], callbacks: usernames

def all_users
  (maintainers + members).to_set
end

include GithubCookbook::Helpers

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
end

def sync_all_members
  remove_members(all_current - all_users)
  add_members(:maintainer, maintainers.to_set - current_maintainers)
  add_members(:member, members.to_set - current_members)
end

def remove_members(users)
  return if users.empty?
  users.each do |user|
    converge_by "Removing #{user} from #{name}" do
      github.remove_team_member id, user
    end
  end
end

def add_members(type, users)
  return if users.empty?
  skip_pending_members(users, type).each do |user|
    converge_by "Adding #{user} to #{name} as #{type}" do
      github.add_team_membership id, user, role: type
    end
  end
end

def skip_pending_members(users, type)
  users.reject do |user|
    pending = membership_pending?(user, type)
    if pending
      log "Membership pending for #{user} to #{name} as #{type}" do
        level :warn
      end
    end
    pending
  end
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

def all_current
  current_maintainers + current_members
end

def current_maintainers
  @current_maintainers ||= get_members(:maintainer)
end

def current_members
  @current_members ||= get_members(:member)
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
  github.team_members(id, role: type).map(&:login).to_set
end

def membership_pending?(user, type)
  membership = github.team_membership(id, user)
  membership[:state] == 'pending' && membership[:role] == type.to_s
rescue Octokit::NotFound
  false
end
