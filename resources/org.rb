require 'set'

actions :sync
default_action :sync

namelist = lambda do |names|
  names.all? { |name| name.is_a?(String) }
end

attribute :name, kind_of: [String, Symbol], required: true, name_attribute: true
attribute :admins, kind_of: Array, required: false, default: [],
                   callbacks: { "should be list of usernames" => namelist }
attribute :members, kind_of: Array, required: false, default: [],
                    callbacks: { "should be list of usernames" => namelist }

def org
  name
end

def all_users
  (admins + members).to_set
end
