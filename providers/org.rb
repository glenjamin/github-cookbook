require 'set'

use_inline_resources

def whyrun_supported?
  true
end

include GithubCookbook::Helpers

action :sync do
  r = new_resource
  remove_members(all_current.reject { |m| r.all_users.include?(m) })
  add_members(:admin, r.admins.reject { |m| current_admins.include?(m) })
  add_members(:member, r.members.reject { |m| current_members.include?(m) })
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

def org
  new_resource.org
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
rescue Octokit::NotFound
  []
end

def membership_pending?(user, type)
  membership = github.org_membership(org, user: user)
  membership[:state] == 'pending' && membership[:role] == type.to_s
rescue
  false
end
