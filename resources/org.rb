require 'set'

usernames = {
  "should be list of usernames" => lambda do |names|
    names.all? { |name| name.is_a?(String) }
  end
}

property :name, [String, Symbol], required: true, name_property: true
property :admins, Array, required: false, default: [], callbacks: usernames
property :members, Array, required: false, default: [], callbacks: usernames

def org
  name
end

def all_users
  (admins + members).to_set
end

include GithubCookbook::Helpers

action :sync do
  remove_members(all_current.reject { |m| all_users.include?(m) })
  add_members(:admin, admins.reject { |m| current_admins.include?(m) })
  add_members(:member, members.reject { |m| current_members.include?(m) })
end

def add_members(type, users)
  return if users.empty?
  skip_pending_members(users, type).each do |user|
    converge_by "Adding #{user} to #{org} as #{type}" do
      github.update_org_membership org, role: type, user: user
    end
  end
end

def remove_members(users)
  return if users.empty?
  users.each do |user|
    converge_by "Removing #{user} from #{org}" do
      github.remove_org_member org, user
    end
  end
end

def skip_pending_members(users, type)
  users.reject do |user|
    pending = membership_pending?(user, type)
    if pending
      log "Membership pending for #{user} to #{org} as #{type}" do
        level :warn
      end
    end
    pending
  end
end

def all_current
  current_admins + current_members
end

def current_admins
  @current_admins ||= get_members(:admin)
end

def current_members
  @current_members ||= get_members(:member)
end

def get_members(type)
  github.org_members(org, role: type).map(&:login).to_set
end

def membership_pending?(user, type)
  membership = github.org_membership(org, user: user)
  membership[:state] == 'pending' && membership[:role] == type.to_s
rescue ::Octokit::NotFound
  false
end
