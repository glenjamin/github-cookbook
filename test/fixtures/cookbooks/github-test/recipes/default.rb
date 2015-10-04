github_repo :test do
  org node['github-test']['org']
  private_repo false
  issues true
  wiki true
  downloads true
  description "Test Repo"
  homepage "http://example.com"
end
