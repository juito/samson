# frozen_string_literal: true
module Kubernetes
  module Api
    class Pod
      def initialize(api_pod)
        @pod = api_pod
      end

      def name
        @pod.metadata.name
      end

      def namespace
        @pod.metadata.namespace
      end

      # jobs are 'Succeeded' ... deploys are 'Running'
      def live?
        (phase == 'Running' && ready?) || (phase == 'Succeeded')
      end

      def restarted?
        @pod.status.containerStatuses.try(:any?) { |s| s.restartCount.positive? }
      end

      def phase
        @pod.status.phase
      end

      def reason
        reasons = []
        reasons.concat @pod.status.conditions.try(:map, &:reason).to_a
        reasons.concat @pod.status.containerStatuses.
          try(:map) { |s| s.to_h.fetch(:state).values.map { |s| s[:reason] } }.
          to_a
        reasons.reject(&:blank?).uniq.join("/").presence || "Unknown"
      end

      def deploy_group_id
        labels.deploy_group_id.to_i
      end

      def role_id
        labels.role_id.to_i
      end

      def containers
        @pod.spec.containers
      end

      private

      def labels
        @pod.metadata.try(:labels)
      end

      def ready?
        if @pod.status.conditions.present?
          ready = @pod.status.conditions.find { |c| c['type'] == 'Ready' }
          ready && ready['status'] == 'True'
        else
          false
        end
      end
    end
  end
end
