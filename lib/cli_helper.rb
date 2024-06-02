# frozen_string_literal: true

module Lima
  # Define CLI helper's error class
  class LimaError < StandardError
  end

  # Helper module to interact with Lima CLI
  class CliHelper
    def initialize(options)
      require 'json'
      require 'logger'
      require 'open3'
      require 'shellwords'
      require 'tempfile'
      require 'yaml'

      @logger = options[:logger] || Logger.new($stderr)
      @limactl = options[:limactl_path] || 'limactl'
      @timeout = options[:timeout] || 600 # 10m
      @lima_info = nil
      @ssh_info = {}
    end

    def info
      return @lima_info if @lima_info

      lima_cmd = [@limactl, 'info']
      stdout_str, stderr_str, status = Open3.capture3(*lima_cmd)
      unless status.success?
        raise LimaError, "`#{lima_cmd.join(' ')}` failed with status #{status.exitstatus}: #{stderr_str}"
      end

      @lima_info = JSON.parse(stdout_str)
    end

    def version
      info['version']
    end

    def list(vm_names = [])
      lima_cmd = [@limactl, 'list', '--json'] + vm_names
      stdout_str, _stderr_str, _status = Open3.capture3(*lima_cmd)

      stdout_str.split("\n").map { |vm| JSON.parse(vm) }
    end

    # A bit faster `list` variant to check the VM status
    def status(vm_name)
      lima_cmd = [@limactl, 'list', '--format', '{{ .Status }}', vm_name]
      stdout_str, _stderr_str, _status = Open3.capture3(*lima_cmd)

      stdout_str.chomp
    end

    def start(vm_name)
      case status(vm_name)
      when ''
        raise LimaError, "Instance '#{vm_name}' not found!"
      when 'Running'
        @logger.debug("'#{vm_name}' is running already, skipping...")
        return true
      end

      lima_cmd = [@limactl, 'start', "--timeout=#{@timeout}s", vm_name]
      _, stderr_str, status = Open3.capture3(*lima_cmd)
      unless status.success?
        raise LimaError, "`#{lima_cmd.join(' ')}` failed with status #{status.exitstatus}: #{stderr_str}"
      end

      true
    end

    def create(vm_name, cfg = {})
      @logger.debug("Options: #{cfg}")

      raise LimaError, "Instance '#{vm_name}' already exists!" if status(vm_name) != ''

      raise LimaError, 'url and config parameters cannot be used together' if cfg[:url] && cfg[:config]

      if cfg[:url]
        cfg_url = cfg[:url]
      elsif cfg[:config]
        # Write config to a temporary YAML file and pass it to limactl later
        safe_name = Shellwords.escape(vm_name)
        tmpfile = Tempfile.new(["lima_#{safe_name}", '.yaml'])
        # config has symbolized keys by default. So .to_yaml will write keys as :symbols.
        # Keys should be stringified to avoid this so Lima can parse the YAML properly.
        tmpfile.write(stringify_keys_recursively(cfg[:config]).to_yaml)
        tmpfile.close

        # Validate the config
        _, stderr_str, status = Open3.capture3(@limactl, 'validate', tmpfile.path)
        unless status.success?
          raise LimaError, "Lima config validation failed with status #{status.exitstatus}: #{stderr_str}"
        end

        cfg_url = tmpfile.path
      else
        raise LimaError, 'Either url or config parameter must be specified'
      end

      lima_cmd = [@limactl, 'create', "--name=#{vm_name}", cfg_url]
      _, stderr_str, status = Open3.capture3(*lima_cmd)
      tmpfile&.unlink # Delete tmpfile if any

      unless status.success?
        raise LimaError, "`#{lima_cmd.join(' ')}` failed with status #{status.exitstatus}: #{stderr_str}"
      end

      true
    end

    def stop(vm_name, force = false)
      lima_cmd = [@limactl, 'stop']
      lima_cmd << '--force' if force
      lima_cmd << vm_name
      _, stderr_str, status = Open3.capture3(*lima_cmd)

      unless status.success?
        @logger.warn("`#{lima_cmd.join(' ')}` failed with status #{status.exitstatus}: #{stderr_str}")
        return false
      end

      true
    end

    def delete(vm_names, force = false)
      lima_cmd = [@limactl, 'delete']
      lima_cmd << '--force' if force
      lima_cmd += vm_names
      _, stderr_str, status = Open3.capture3(*lima_cmd)

      unless status.success?
        @logger.warn("`#{lima_cmd.join(' ')}` failed with status #{status.exitstatus}: #{stderr_str}")
        return false
      end

      true
    end

    def ssh_info(vm_name)
      return @ssh_info[vm_name] if @ssh_info.key? vm_name

      lima_cmd = [@limactl, 'show-ssh', '--format', 'options', vm_name]
      stdout_str, stderr_str, status = Open3.capture3(*lima_cmd)

      if stdout_str.empty?
        @logger.warn("`#{lima_cmd.join(' ')}` failed with status #{status.exitstatus}: #{stderr_str}")
        return {}
      end

      # Convert key=value to [key],[value] pairs array
      vm_opts_pairs = Shellwords.shellwords(stdout_str).map { |x| x.split('=', 2) }

      # Collect all IdentityFile values
      identity_files = vm_opts_pairs.filter { |x| x[0] == 'IdentityFile' }.map { |x| x[1] }

      # Convert pairs array to a hash
      vm_opts = Hash[*vm_opts_pairs.flatten]
      vm_opts['IdentityFile'] = identity_files
      vm_opts['Port'] = vm_opts['Port'].to_i

      @ssh_info[vm_name] = vm_opts
    end

    # Stringify Hash keys recursively
    def stringify_keys_recursively(hash)
      stringified_hash = {}
      hash.each do |k, v|
        stringified_hash[k.to_s] = if v.is_a?(Hash)
                                     stringify_keys_recursively(v)
                                   elsif v.is_a?(Array)
                                     v.map { |x| x.is_a?(Hash) ? stringify_keys_recursively(x) : x }
                                   else
                                     v
                                   end
      end
      stringified_hash
    end
  end
end
