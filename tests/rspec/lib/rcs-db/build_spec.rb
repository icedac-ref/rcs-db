require 'spec_helper'

# Define a fake builder class
# All the real builders (BuildWindows, BuildOSX, etc.) are required an registered
# as soon as "build.rb" is required
module RCS
  module DB
    class BuildFake; end
  end
end

require_db 'db_layer'
require_db 'grid'
require_db 'build'

module RCS
module DB

  describe Build do

    use_db
    silence_alerts

    describe '#initialize' do

      it 'creates a temporary directory' do
        expect(Dir.exist? described_class.new.tmpdir).to be_true
      end

      context 'when called in same instant' do

        before { Time.stub(:now).and_return 42 }

        it 'does not create the same temp directory' do
          expect(described_class.new.tmpdir != described_class.new.tmpdir).to be_true
        end
      end
    end

    context "when builders' classes has been registered" do

      describe '#factory' do

        it 'returns an instance of that factory' do
          expect(described_class.factory(:osx)).to respond_to :patch
        end
      end
    end

    context 'when a class has "Build" in its name' do

      it 'is registered as a factory' do
        expect(described_class.factory(:fake)).to be_kind_of BuildFake
      end
    end

    describe '#load' do

      let!(:operation) { Item.create!(name: 'testoperation', _kind: :operation, path: [], stat: ::Stat.new) }

      let!(:factory) { Item.create!(name: 'testfactory', _kind: :factory, path: [operation.id], stat: ::Stat.new, good: true) }

      let!(:core_content) { File.read fixtures_path('linux_core.zip') }

      let!(:core) { ::Core.create!(name: 'linux', _grid: GridFS.put(core_content), version: 42) }

      context 'when the core is not found' do

        # TODO remove the instance variable @platform in favour of an attr_accessor (for example)
        before { subject.instance_variable_set '@platform', :amiga }

        it 'raises an error' do
          expect { subject.load(nil) }.to raise_error RuntimeError, /core for amiga not found/i
        end
      end

      before { subject.instance_variable_set '@platform', :linux }

      it 'saves to core content to the temporary folder' do
        subject.load nil
        expect(File.read subject.core_filepath).to be_eql core_content.force_encoding('utf-8')
      end

      it 'finds the given factory' do
        expect { subject.load('_id' => factory.id) }.to change(subject, :factory).from(nil).to(factory)
      end
    end
  end

end
end
