require 'presenters/v3/base_presenter'
require 'presenters/mixins/metadata_presentation_helpers'

module VCAP::CloudController
  module Presenters
    module V3
      class BuildPresenter < BasePresenter
        include VCAP::CloudController::Presenters::Mixins::MetadataPresentationHelpers

        class << self
          # :labels and :annotations come from MetadataPresentationHelpers
          def associated_resources
            super + [ :kpack_lifecycle_data, { buildpack_lifecycle_data: :buildpack_lifecycle_buildpacks } ]
          end
        end

        def to_hash
          {
            guid: build.guid,
            created_at: build.created_at,
            updated_at: build.updated_at,
            state: build.state,
            error: error,
            lifecycle: {
              type: build.lifecycle_type,
              data: build.lifecycle_data.to_hash
            },
            package: { guid: build.package_guid },
            droplet: droplet,
            relationships: { app: { data: { guid: build.app_guid } } },
            metadata: {
              labels: hashified_labels(build.labels),
              annotations: hashified_annotations(build.annotations),
            },
            links: build_links,
            created_by: {
              guid: build.created_by_user_guid,
              name: build.created_by_user_name,
              email: build.created_by_user_email,
            }
          }
        end

        private

        def build
          @resource
        end

        def droplet
          if build.droplet&.in_final_state?
            return { guid: build.droplet.guid, href: url_builder.build_url(path: "/v3/droplets/#{build.droplet.guid}") }
          end

          nil
        end

        def error
          e = [build.error_id, build.error_description].compact.join(' - ')
          e.blank? ? nil : e
        end

        def build_links
          {
            self: { href: url_builder.build_url(path: "/v3/builds/#{build.guid}") },
            app: { href: url_builder.build_url(path: "/v3/apps/#{build.app.guid}") },
          }
        end

        def url_builder
          @url_builder ||= VCAP::CloudController::Presenters::ApiUrlBuilder.new
        end
      end
    end
  end
end
