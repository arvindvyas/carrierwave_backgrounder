# encoding: utf-8
require 'spec_helper'
require 'backgrounder/workers/store_asset'

describe CarrierWave::Workers::StoreAsset do
  let(:fixtures_path) { File.expand_path('../fixtures/images', __FILE__) }
  let(:worker_class) { CarrierWave::Workers::StoreAsset }
  let(:user) { mock('User') }
  let!(:worker) { worker_class.new(user, '22', :image) }

  context ".perform" do

    it 'creates a new instance and calls perform' do
      args = [user, '22', :image]
      worker_class.expects(:new).with(*args).returns(worker)
      worker_class.any_instance.expects(:perform)

      worker_class.perform(*args)
    end
  end

  context "#perform" do
    let(:image)  { mock('UserAsset') }

    before do
      image.expects(:root).once.returns(File.expand_path('..', __FILE__))
      image.expects(:cache_dir).once.returns('fixtures')
      user.expects(:image_tmp).twice.returns('images/test.jpg')
      user.expects(:find).with('22').once.returns(user)
      user.expects(:image).once.returns(image)
      user.expects(:process_image_upload=).with(true).once
      user.expects(:image=).once
      user.expects(:image_tmp=).with(nil).once
    end

    it 'removes tmp directory on success' do
      FileUtils.expects(:rm_r).with(fixtures_path, :force => true).once
      user.expects(:save!).once.returns(true)
      worker.perform
    end

    it 'does not remove the tmp directory if save! fails' do
      FileUtils.expects(:rm_r).never
      user.expects(:save!).once.returns(false)
      worker.perform
    end

    it 'sets the cache_path' do
      user.expects(:save!).once.returns(false)
      worker.perform
      expect(worker.cache_path).to eql(fixtures_path + '/test.jpg')
    end

    it 'sets the tmp_directory' do
      user.expects(:save!).once.returns(false)
      worker.perform
      expect(worker.tmp_directory).to eql(fixtures_path)
    end
  end

  describe '#perform with args' do
    let(:admin) { mock('Admin') }
    let(:image)  { mock('AdminAsset') }
    let(:worker) { worker_class.new }

    before do
      image.expects(:root).once.returns(File.expand_path('..', __FILE__))
      image.expects(:cache_dir).once.returns('fixtures')
      admin.expects(:avatar_tmp).twice.returns('images/test.jpg')
      admin.expects(:find).with('23').once.returns(admin)
      admin.expects(:avatar).once.returns(image)
      admin.expects(:process_avatar_upload=).with(true).once
      admin.expects(:avatar=).once
      admin.expects(:avatar_tmp=).with(nil).once
      admin.expects(:save!).once.returns(false)
      worker.perform admin, '23', :avatar
    end

    it 'sets klass' do
      expect(worker.klass).to eql(admin)
    end

    it 'sets column' do
      expect(worker.id).to eql('23')
    end

    it 'sets id' do
      expect(worker.column).to eql(:avatar)
    end
  end
end
