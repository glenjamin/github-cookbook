github_org node['github-test']['org'] do
  admins %w(glenjamin)
  members %w(glenjamin1 glenjamin2 glenjamin3 glenjamin4)
end

github_repo 'test1' do
  org node['github-test']['org']
  private_repo false
  issues true
  wiki true
  downloads true
  description "Test Repo 1"
  homepage "http://example.com"
end

github_repo 'test2' do
  org node['github-test']['org']
  private_repo false
  issues true
  wiki true
  downloads true
  description "Test Repo 2"
  homepage "http://example.com"
end

github_repo 'test3' do
  org node['github-test']['org']
  private_repo false
  issues true
  wiki true
  downloads true
  description "Test Repo 3"
  homepage "http://example.com"
end

github_team "america" do
  org node['github-test']['org']
  description "bad pun"
  privacy :closed

  maintainers %w(glenjamin3)
  members %w(glenjamin glenjamin1 glenjamin2)

  admin_repos %w(test1)
  push_repos %w(test2)
  pull_repos %w(test3)
end

github_team "player" do
  org node['github-test']['org']
  privacy :secret

  maintainers %w(glenjamin1)
  members %w(glenjamin3 glenjamin4)

  admin_repos %w(test1 test2)
  push_repos %w(test3)
end
