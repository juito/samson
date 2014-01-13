require 'flowdock'

class FlowdockNotification
  def initialize(stage, deploy)
    @stage, @deploy = stage, deploy
    @project = @stage.project
    @user = @deploy.user
  end

  def deliver
    subject = "[#{@project.name}] #{@deploy.summary}"
    flow.push_to_team_inbox(subject: subject, content: @deploy.summary)
  rescue Flowdock::Flow::ApiError
    # Invalid token or something.
  end

  private

  def flow
    @flow ||= Flowdock::Flow.new(
      api_token: @stage.flowdock_tokens,
      source: "pusher",
      from: { name: @user.name, address: @user.email }
    )
  end
end