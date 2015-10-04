actions :create
default_action :create

boolean = [TrueClass, FalseClass]

attribute :name, kind_of: [String, Symbol], required: true, name_attribute: true
attribute :org, kind_of: [String, Symbol], required: true
attribute :private_repo, kind_of: boolean, required: true
attribute :description, kind_of: String, required: false
attribute :homepage, kind_of: String, required: false
attribute :issues, kind_of: boolean, required: false, default: false
attribute :wiki, kind_of: boolean, required: false, default: false
attribute :downloads, kind_of: boolean, required: false, default: true

def slug
  "#{org}/#{name}"
end
