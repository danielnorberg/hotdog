#!/usr/bin/env ruby

require "fileutils"

module Hotdog
  module Commands
    class Untag < BaseCommand
      def define_options(optparse, options={})
        default_option(options, :retry, 5)
        default_option(options, :tag_source, "user")
        default_option(options, :tags, [])
        optparse.on("--retry NUM") do |v|
          options[:retry] = v.to_i
        end
        optparse.on("--retry-delay SECONDS") do |v|
          options[:retry_delay] = v.to_i
        end
        optparse.on("--source SOURCE") do |v|
          options[:tag_source] = v
        end
        optparse.on("-a TAG", "-t TAG", "--tag TAG", "Use specified tag name/value") do |v|
          options[:tags] << v
        end
      end

      def run(args=[], options={})
        args.each do |host_name|
          host_name = host_name.sub(/\Ahost:/, "")

          if options[:tags].empty?
            # delete all user tags
            with_retry do
              detach_tags(host_name, source=options[:tag_source])
            end
          else
            host_tags = with_retry { host_tags(host_name, source=options[:tag_source]) }
            old_tags = host_tags["tags"]
            new_tags = old_tags - options[:tags]
            if old_tags == new_tags
              # nop
            else
              with_retry do
                update_tags(host_name, new_tags, source=options[:tag_source])
              end
            end
          end
        end

        # Remove persistent.db to schedule update on next invocation
        if @db
          close_db(@db)
        end
        FileUtils.rm_f(File.join(options[:confdir], PERSISTENT_DB))
      end

      private
      def detach_tags(host_name, options={})
        code, detach_tags = dog.detach_tags(host_name, options)
        if code.to_i / 100 != 2
          raise("dog.detach_tags(#{host_name.inspect}, #{options.inspect}) returns [#{code.inspect}, #{detach_tags.inspect}]")
        end
        detach_tags
      end

      def host_tags(host_name, options={})
        code, host_tags = dog.host_tags(host_name, options)
        if code.to_i / 100 != 2
          raise("dog.host_tags(#{host_name.inspect}, #{options.inspect}) returns [#{code.inspect}, #{host_tags.inspect}]")
        end
        host_tags
      end

      def update_tags(host_name, tags, options={})
        code, update_tags = dog.update_tags(host_name, tags, options)
        if code.to_i / 100 != 2
          raise("dog.update_tags(#{host_name.inspect}, #{tags.inspect}, #{options.inspect}) returns [#{code.inspect}, #{update_tags.inspect}]")
        end
        update_tags
      end
    end
  end
end

# vim:set ft=ruby :
