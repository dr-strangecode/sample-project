#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

REGION_FILTER_REGEX = /[a-z0-9-]/

require 'thor'
require 'json'
require 'rest-client'
require 'uuid'
require 'fileutils'
require 'ip'

class Exit
  def initialize(message)
    puts message
    exit 1
  end
end

class Validator
  class << self
    def check_characters(region_filter)
      Exit.new("No region passed. Must supply a region.") if region_filter.empty?
      region_filter.split("").each {|x| Exit.new("May only use [0-9], [a-z] or '-' characters for a region. This is case sensitive.") unless REGION_FILTER_REGEX =~ x }
    end

    def check_region(region_filter)
      Exit.new("'#{region_filter}' is not a valid region.\nValid Regions: #{Regions.list}") unless Regions.list.include?(region_filter)
    end
  end
end

class Regions
  class << self
    def list
      @@list ||= Store.load_prefixes.collect {|x| x['region']}.sort.uniq
    end
  end
end

class Setup
  class << self
    def create_directories(dir_list)
      Exit.new("Must pass a list argument.") unless dir_list.class == Array
      dir_list.each {|dir| FileUtils.remove_dir(dir) if File.directory?(dir) }
      dir_list.each {|dir| Dir.mkdir(dir) unless File.directory?(dir) }
    end

    def fetch_ips
      result = RestClient.get 'https://ip-ranges.amazonaws.com/ip-ranges.json'
      Store.store_results(result.body, 'ip-ranges.json', 'incoming')
    end
  end
end

class Store
  class << self
    def store_results(result, file_name, directory)
      File.open("#{Dir.pwd}/#{directory}/#{file_name}", 'w') { |file| file.write(result) }
    end

    def load_results(file_name, directory)
      File.read("#{Dir.pwd}/#{directory}/#{file_name}")
    end

    def load_prefixes
      JSON.parse(load_results('ip-ranges.json', 'incoming'))['prefixes'].collect {|x| x if x['service'] == 'EC2'}.reject! {|x| x.nil?}
    end
  end
end

class Parser
  class << self
    def parse_ips(region_filter)
      prefixes = Store.load_prefixes
      out = {}
      Regions.list.each {|region| out[region] = []}
      prefixes.each {|prefix| out[prefix['region']].append IPRange.new(prefix)}
      out.each {|region, prefix_set| Store.store_results(prefix_set.collect {|prefix| prefix.to_h}.to_json, "#{region}.json", "ec2_by_region")}
      out[region_filter].each {|prefix| Store.store_results(prefix.to_json, "#{prefix.id}.json", "ec2_filtered")}
      networks = out[region_filter].collect {|x| x.ip_prefix}.sort
      consolidated_networks = IPRangerator.consolidate(networks)
      Store.store_results(consolidated_networks.to_json, "extra_credit.json", "ec2_by_region")
    end
  end
end

class IPRangerator
  class << self
    def consolidate(ip_list)
      subnet_range = {}
      for i in 8..31 do
        subnet_range[IP.new("10.0.0.0/#{i}").size.to_s] = i.to_s
      end
      new_list = []
      new_size = 0
      flag = false
      start = nil
      backup_list = []
      for i in 0..ip_list.size-1 do
        # beginning of contiguous range
        if (i != ip_list.size - 1) && (ip_list[i].network(ip_list[i].size).to_addr == ip_list[i+1].to_addr) then
          flag = true
          start = ip_list[i].dup if start.nil?
          backup_list << ip_list[i].dup
          new_size += ip_list[i].size
        # end of contiguous range
        elsif flag == true
          new_size += ip_list[i].size
          # some ranges I can't figure out how to consolidate
          # ex: #<IP::V4 55.2.0.0/15>, #<IP::V4 55.4.0.0/16> - in theory they're contiguous, but I don't know how to consolidate them
          if subnet_range[new_size.to_s].nil? then
            new_list << backup_list
            new_list << ip_list[i]
          else
            start.pfxlen = subnet_range[new_size.to_s].to_i
            new_list << start
          end
          start = nil
          new_size = 0
          flag = false
          backup_list = []
        # non-contigous range
        else
          new_list << ip_list[i].dup
          backup_list = []
        end
      end
      return new_list.flatten
    end

  end
end

class IPRange
  attr_reader :id, :region, :service
  attr_accessor :ip_prefix, :original_ip

  def initialize(json)
    @id = UUID.generate
    @region = json['region']
    @service = json['service']
    @original_ip = IP.new(json['ip_prefix'])
    @ip_prefix = original_ip.network(655360)
  end

  def <=>(other)
    ip_prefix <=> other.ip_prefix
  end

  def to_json
    self.to_h.to_json
  end

  def to_h
    {'id': @id, 'region': @region, 'service': @service, 'ip_prefix': @ip_prefix}
  end

  def store!
    Store.store_results(self.to_json, "#{@id}.json", 'ec2-filtered')
  end
end

class Runner < Thor

  desc "parse_region <region>", "parse a particular region of AWS EC2 ips"
  def parse_region(region_filter="")
    Validator.check_characters(region_filter)
    Setup.create_directories(['incoming','ec2_by_region','ec2_filtered'])
    Setup.fetch_ips
    Validator.check_region(region_filter)
    Parser.parse_ips(region_filter)
  end
end

Runner.start(ARGV)
