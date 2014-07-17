# encoding: UTF-8
require 'easy_type'
require 'ruby-debug'

# @nodoc
module Puppet
  newtype(:partition) do
    include EasyType
    include EasyType::Helpers

    COLUMNS = ['minor','start','end','size','part_type','fs_type', 'flags', 'label_type', 'device']

    desc "create and modify partitions on a disk"

    ensurable

    set_command(:parted)

    to_get_raw_resources do
      @current_device_name = ''
      @partition_type = ''
      @in_table = false
      @return_value = []
      output = parted '-l units MiB'
      output.each_line do | line|
        line && line.chop!
        end_of_table_filter(line)
        partition_table_filter(line)
        table_line_filter(line)
        device_name_filter(line)
        start_of_table_filter(line)
      end
      @return_value
    end


    on_create do | command_builder |
      puts 'create'
    end

    on_modify do | command_builder|
      puts 'modify'
    end

    on_destroy do |command_builder|
      puts 'destroy'
    end

    #
    # Title is device/name
    #
    map_title_to_attributes(:name, :device, :minor) do
      /^((.*):(.*))$/
    end

    parameter :name
    parameter :device
    parameter :minor
		property  :start
		property  :end
		property  :fs_type
		property  :part_type
		property  :boot
		property  :lba
		property  :root
		property  :swap
		property  :hidden
		property  :raid
		property  :lvm
    # -- end of attributes -- Leave this comment if you want to use the scaffolder
    #


    def self.device_name_filter(line)
      device = line.scan(/^Disk \/dev\/(.*):.*$/).flatten.first
      @current_device_name = device if device
    end

    def self.partition_table_filter(line)
      type = line.scan(/^Partition Table: (.*)$/).flatten.first
      @partition_type = type if type
    end

    def self.start_of_table_filter(line)
      start_of_table = /^Number\s*Start\s*End\s*Size\s*Type\s*File\s*system\s*Flags$/.match(line)
      @in_table = true if start_of_table
    end

    def self.end_of_table_filter(line)
      @in_table = false if @in_table and line == ""
    end

    def self.table_line_filter(line)
      if @in_table
        data = line.scan(/^\s(\S*\s)\s*(\s\S*\s)\s*(\s\S*\s)\s*(\s\S*\s)\s*(\s\S*\s)\s*(\s\S*\s)\s*(\s\S*\s)/).flatten
        data.map!(&:strip)
        data << @partition_type << @current_device_name
        @return_value << EasyType::Helpers::InstancesResults[COLUMNS.zip(data)]
      end
    end




  end
end
