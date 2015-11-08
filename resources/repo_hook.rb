require 'uri'
url_regex = URI.regexp(%w(http https))

property :identifier, [String, Symbol], required: true, name_property: true
property :repo, [String, Symbol], required: true
property :org, [String, Symbol], required: true
property :type, [String, Symbol], required: true, coerce: ->(t) { t.to_sym }
property :hook_events, Array, required: true, callbacks: {
  "should be list of events" => lambda do |events|
    events.all? { |event| event =~ /^[a-z][a-z\_]+$/ }
  end
}
property :url, String, required: false, callbacks: {
  "should be an absolute URL" => ->(url) { url =~ /\A#{url_regex}\z/ }
}
property :content_type, [:json, :form], required: false, default: :json
property :config, Hash, required: false, default: {}

def after_created
  if webhook?
    fail "url is required for webhooks" if url.to_s.empty?
  else
    fail "url must be omitted for service hooks" unless url.to_s.empty?
  end
end

def slug
  "#{org}/#{repo}"
end

def webhook?
  type == :web
end

include GithubCookbook::Helpers
include GithubCookbook::ConvergeBy
include Chef::DSL::Recipe::FullDSL

action :create do
  if current_hook && !changes.empty?
    converge_by "Updating repo #{slug} hook #{desc}: #{changes.inspect}" do
      github.edit_hook(slug, id, type, hook_config, options)
    end
  elsif !current_hook
    converge_by "Creating repo #{slug} hook #{desc}" do
      github.create_hook(slug, type, hook_config, options)
    end
  end
end

action :delete do
  if current_hook
    converge_by "Deleting repo #{slug} hook #{desc}" do
      github.remove_hook(slug, id)
    end
  end
end

def desc
  webhook? ? url : type
end

def hook_config
  if webhook?
    config.merge(url: url, content_type: content_type, identifier: identifier)
  else
    config
  end
end

def options
  { events: hook_events, active: true }
end

def id
  current_hook.id
end

def current_hook
  @current_hook ||= github.hooks(slug).find { |hook| same_hook(hook) }
end

def same_hook(hook)
  return false unless hook['name'].to_sym == type

  return true unless webhook?

  hook['config']['identifier'] == identifier
end

def changes
  changes = hook_changes
  config = config_changes
  changes[:config] = config unless config.empty?
  changes
end

def config_changes
  hook_config.select { |k, v| v.to_s != current_hook.config[k].to_s }
end

def hook_changes
  options.select { |k, v| v.to_s != current_hook[k].to_s }
end
