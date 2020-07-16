require 'spec_helper'
require_relative 'lifecycle_shared'

module VCAP::CloudController
  RSpec.describe KpackLifecycle do
    subject(:lifecycle) { KpackLifecycle.new(package, staging_message) }
    let(:app) { AppModel.make }
    let(:package) { PackageModel.make(app: app) }
    let(:requested_buildpacks) { [] }
    let(:staging_message) { BuildCreateMessage.new(lifecycle: { data: { buildpacks: requested_buildpacks }, type: 'kpack' }) }
    let(:k8s_buildpacks) { [{ name: 'some-buildpack' }, { name: 'super-duper-buildpack' }] }

    it_behaves_like 'a lifecycle'

    before do
      allow_any_instance_of(KpackBuildpackListFetcher).to receive(:fetch_all).and_return(k8s_buildpacks)
    end

    context('no buildpacks requested') do
      it 'is valid' do
        expect(lifecycle).to be_valid
      end

      it 'has an empty list of buildpack_infos' do
        expect(lifecycle.buildpack_infos).to be_empty
      end
    end

    context('buildpacks requested') do
      context('a single present buildpack') do
        let(:requested_buildpacks) { ['some-buildpack'] }

        it 'sets the buildpack_infos correctly' do
          expect(lifecycle).to be_valid
          expect(lifecycle.buildpack_infos).to contain_exactly('some-buildpack')
        end
      end

      context('multiple present buildpacks') do
        let(:requested_buildpacks) { ['some-buildpack', 'super-duper-buildpack'] }

        it 'sets the buildpack_infos correctly' do
          expect(lifecycle).to be_valid
          expect(lifecycle.buildpack_infos).to contain_exactly('some-buildpack', 'super-duper-buildpack')
        end
      end

      context('a single NOT-present buildpack') do
        let(:requested_buildpacks) { ['bogus-buildpack'] }

        it 'lists the not-present buildpacks in the error' do
          expect(lifecycle).not_to be_valid

          expect(lifecycle.errors[:buildpack]).to include('"bogus-buildpack" must be an existing buildpack configured for use with kpack')
        end
      end

      context('multiple NOT-present buildpacks') do
        let(:requested_buildpacks) { ['bogus-buildpack', 'bunko-buildpack', 'capi-fail-buildpack'] }

        it 'lists the not-present buildpacks in the error' do
          expect(lifecycle).not_to be_valid

          expect(lifecycle.errors[:buildpack]).to include('"bogus-buildpack" must be an existing buildpack configured for use with kpack')
          expect(lifecycle.errors[:buildpack]).to include('"bunko-buildpack" must be an existing buildpack configured for use with kpack')
          expect(lifecycle.errors[:buildpack]).to include('"capi-fail-buildpack" must be an existing buildpack configured for use with kpack')
        end
      end

      context('a mix of present and NOT-present buildpacks') do
        let(:requested_buildpacks) { ['some-buildpack', 'bunko-buildpack', 'capi-fail-buildpack'] }

        it 'lists the not-present buildpacks in the error' do
          expect(lifecycle).not_to be_valid

          expect(lifecycle.errors[:buildpack]).to include('"bunko-buildpack" must be an existing buildpack configured for use with kpack')
          expect(lifecycle.errors[:buildpack]).to include('"capi-fail-buildpack" must be an existing buildpack configured for use with kpack')
        end
      end
    end
  end
end
