github_org node['github-test']['org'] do
  admins ['glenjamin']
  members ['sky-glenjamin']
end

github_team "america" do
  org node['github-test']['org']
  privacy :closed
end

github_team "player" do
  org node['github-test']['org']
  privacy :secret
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
