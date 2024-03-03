# frozen_string_literal: true

require 'spec_helper'
require 'cli_helper'

module Lima
  describe CliHelper do
    let(:options) do
      {
        logger: logger,
        timeout: 900,
      }
    end
    let(:lima_success) do
      rc = instance_double(Process::Status)
      allow(rc).to receive(:success?).and_return(true)
      allow(rc).to receive(:exitstatus).and_return(0)
      rc
    end
    let(:lima_failure) do
      rc = instance_double(Process::Status)
      allow(rc).to receive(:success?).and_return(false)
      allow(rc).to receive(:exitstatus).and_return(123)
      rc
    end
    let(:lima_result) { lima_success }
    let(:vm_name) { 'test_vm' }
    let(:vm_status) { '' }
    let(:lima_helper) { described_class.new(options) }
    let(:logger) do
      lgr = instance_double(Logger)
      allow(lgr).to receive(:warn)
      allow(lgr).to receive(:debug)
      lgr
    end

    describe '#info' do
      let(:limactl_info) { { 'version' => '1.2.3' } }

      it 'returns `limactl info` output' do
        allow(Open3).to receive(:capture3).with('limactl', 'info')
                                          .and_return([limactl_info.to_json, '', lima_success])

        result = lima_helper.info
        expect(Open3).to have_received(:capture3).with('limactl', 'info').once
        expect(result).to eq(limactl_info)
      end
    end

    describe '#list' do
      let(:limactl_list) do
        [
          { 'name' => 'docker',  'status' => 'Running' },
          { 'name' => 'podman',  'status' => 'Stopped' },
        ]
      end
      let(:limactl_stdout) { limactl_list.map(&:to_json).join("\n") }

      it 'returns `limactl list` output' do
        allow(Open3).to receive(:capture3).with('limactl', 'list', '--json', 'docker', 'podman')
                                          .and_return([limactl_stdout, '', lima_success])

        result = lima_helper.list(['docker', 'podman'])
        expect(Open3).to have_received(:capture3).with('limactl', 'list', '--json', 'docker', 'podman').once
        expect(result).to eq(limactl_list)
      end
    end

    describe '#status' do
      let(:vm_status) { 'Running' }
      let(:limactl_list) { [{ 'name' => vm_name, 'status' => vm_status }] }

      it 'returns the VM status' do
        allow(Open3).to receive(:capture3).with('limactl', 'list', '--format', '{{ .Status }}', vm_name)
                                          .and_return([vm_status, '', lima_result])

        result = lima_helper.status(vm_name)
        expect(Open3).to have_received(:capture3).with('limactl', 'list', '--format', '{{ .Status }}', vm_name).once
        expect(result).to eq(vm_status)
      end
    end

    describe '#start' do
      context 'with existsing VM' do
        let(:vm_status) { 'Stopped' }

        it 'starts the VM' do
          allow(Open3).to receive(:capture3).with('limactl', 'list', '--format', '{{ .Status }}', vm_name)
                                            .and_return([vm_status, '', lima_success])
          allow(Open3).to receive(:capture3).with('limactl', 'start', "--timeout=#{options[:timeout]}s", vm_name)
                                            .and_return([vm_status, '', lima_success])

          result = lima_helper.start(vm_name)
          expect(Open3).to have_received(:capture3)
            .with('limactl', 'list', '--format', '{{ .Status }}', vm_name)
            .once
          expect(Open3).to have_received(:capture3)
            .with('limactl', 'start', "--timeout=#{options[:timeout]}s", vm_name)
            .once
          expect(result).to be true
        end
      end

      context 'with non-existent VM name' do
        let(:vm_name) { 'nonexistent' }

        it 'raises an exception' do
          allow(Open3).to receive(:capture3).with('limactl', 'list', '--format', '{{ .Status }}', vm_name)
                                            .and_return([vm_status, '', lima_success])

          expect { lima_helper.start(vm_name) }.to raise_error(LimaError, %r{'nonexistent' not found})
        end
      end
    end

    describe '#create' do
      context 'with existing VM' do
        let(:vm_status) { 'Stopped' }

        it 'raises an exception' do
          allow(Open3).to receive(:capture3).with('limactl', 'list', '--format', '{{ .Status }}', vm_name)
                                            .and_return([vm_status, '', lima_success])

          expect { lima_helper.create(vm_name, {}) }.to raise_error(LimaError, %r{'#{vm_name}' already exists})
        end
      end

      context 'with non-existent VM name' do
        before :each do
          allow(Open3).to receive(:capture3)
            .with('limactl', 'list', '--format', '{{ .Status }}', vm_name)
            .and_return([vm_status, '', lima_success])
        end
        after :each do
          expect(Open3).to have_received(:capture3)
            .with('limactl', 'list', '--format', '{{ .Status }}', vm_name)
            .once
        end

        context 'with url' do
          let(:cfg) { { url: 'template://ubuntu-lts' } }

          it 'creates the VM' do
            allow(Open3).to receive(:capture3)
              .with('limactl', 'create', "--name=#{vm_name}", "--timeout=#{options[:timeout]}s", cfg[:url])
              .and_return(['', '', lima_success])

            result = lima_helper.create(vm_name, cfg)
            expect(Open3).to have_received(:capture3)
              .with('limactl', 'create', "--name=#{vm_name}", "--timeout=#{options[:timeout]}s", cfg[:url])
              .once
            expect(result).to be true
          end
        end

        context 'with config' do
          let(:cfg) { { config: { images: ['https://example.com/lima.qcow2'] } } }
          let(:tmpfile) { Tempfile.new(["lima_#{vm_name}", '.yaml']) }

          before :each do
            allow(Tempfile).to receive(:new).and_return(tmpfile)
          end
          after :each do
            tmpfile.close
            tmpfile.unlink
          end

          it 'creates the VM' do
            saved_path = tmpfile.path
            allow(Open3).to receive(:capture3).with('limactl', 'validate', saved_path)
                                              .and_return(['', '', lima_success])
            allow(Open3).to receive(:capture3)
              .with('limactl', 'create', "--name=#{vm_name}", "--timeout=#{options[:timeout]}s", saved_path)
              .and_return(['', '', lima_success])

            result = lima_helper.create(vm_name, cfg)
            expect(Open3).to have_received(:capture3).with('limactl', 'validate', saved_path).once
            expect(Open3).to have_received(:capture3)
              .with('limactl', 'create', "--name=#{vm_name}", "--timeout=#{options[:timeout]}s", saved_path)
              .once
            expect(result).to be true
          end
        end

        context 'with url&config' do
          let(:cfg) do
            {
              url: 'template://ubuntu-lts',
              config: { images: ['https://example.com/lima.qcow2'] },
            }
          end

          it 'raises an exception' do
            allow(Open3).to receive(:capture3).with('limactl', 'list', '--format', '{{ .Status }}', vm_name)
                                              .and_return([vm_status, '', lima_success])

            expect { lima_helper.create(vm_name, cfg) }.to raise_error(LimaError, %r{url and config parameters cannot be used together})
          end
        end

        context 'without url&config' do
          it 'raises an exception' do
            allow(Open3).to receive(:capture3).with('limactl', 'list', '--format', '{{ .Status }}', vm_name)
                                              .and_return([vm_status, '', lima_success])

            expect { lima_helper.create(vm_name) }.to raise_error(LimaError, %r{url or config parameter must be specified})
          end
        end
      end
    end

    describe '#stop' do
      let(:vm_status) { 'Stopped' }

      it 'stops the VM' do
        allow(Open3).to receive(:capture3).with('limactl', 'stop', vm_name)
                                          .and_return(['', '', lima_success])

        result = lima_helper.stop(vm_name)
        expect(Open3).to have_received(:capture3).with('limactl', 'stop', vm_name).once
        expect(result).to be(true)
      end
    end

    describe '#delete' do
      let(:vms) { ['test', 'example'] }

      it 'deletes the VM' do
        allow(Open3).to receive(:capture3).with('limactl', 'delete', *vms)
                                          .and_return(['', '', lima_success])

        result = lima_helper.delete(vms)
        expect(Open3).to have_received(:capture3).with('limactl', 'delete', *vms).once
        expect(result).to be(true)
      end
    end

    describe '#ssh_info' do
      let(:limactl_stdout) do
        <<~LIMA
          IdentityFile="/home/test/.lima/_config/user"
          IdentityFile="/home/test/.ssh/id_rsa"
          PreferredAuthentications=publickey
          User=test
          Hostname=127.0.0.1
          Port=54321
        LIMA
      end
      let(:ssh_info) do
        {
          'IdentityFile' => [
            '/home/test/.lima/_config/user',
            '/home/test/.ssh/id_rsa',
          ],
          'PreferredAuthentications' => 'publickey',
          'User' => 'test',
          'Hostname' => '127.0.0.1',
          'Port' => 54_321,
        }
      end

      it 'returns the VM ssh connection info' do
        allow(Open3).to receive(:capture3).with('limactl', 'show-ssh', '--format', 'options', vm_name)
                                          .and_return([limactl_stdout, '', lima_success])

        result = lima_helper.ssh_info(vm_name)
        expect(Open3).to have_received(:capture3).with('limactl', 'show-ssh', '--format', 'options', vm_name).once
        expect(result).to eq(ssh_info)
      end
    end
  end
end
