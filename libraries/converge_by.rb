module GithubCookbook
  module ConvergeBy
    include Chef::Mixin::WhyRun

    def converge_by(descriptions, &block)
      converge_actions.add_action(descriptions, &block)
      updated_by_last_action(true)
    end

    protected

    def converge_actions
      @converge_actions ||= ConvergeActions.new(self, run_context, action)
    end
  end
end
