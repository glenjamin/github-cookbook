github_org node['github-test']['org'] do
  admins %w(glenjamin)
  members %w(glenjamin1 glenjamin2 glenjamin3 glenjamin4)
end

github_team "america" do
  org node['github-test']['org']
  description "bad pun"
  privacy :closed
  maintainers %w(glenjamin3)
  members %w(glenjamin glenjamin1 glenjamin2)
end

github_team "player" do
  org node['github-test']['org']
  privacy :secret
  maintainers %w(glenjamin1)
  members %w(glenjamin3 glenjamin4)
end

github_repo :test do
  org node['github-test']['org']
  private_repo false
  issues true
  wiki true
  downloads true
  description "Test Repo"
  homepage "http://example.com"
end
