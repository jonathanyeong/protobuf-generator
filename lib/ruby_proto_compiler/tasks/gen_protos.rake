# frozen_string_literal: true
require 'open-uri'
require 'rubygems/package'
require 'zlib'

TAR_LONGLINK = '././@LongLink'  # http://dracoater.blogspot.com/2013/10/extracting-files-from-targz-with-ruby.html
TAR_EXT = '.tar.gz'.freeze
DEFAULT_OUTPUT_DIR = 'lib/messages/'.freeze
DEFAULT_DOWNLOAD_DIR = 'tmp/'

namespace :ruby_proto_compiler do
  @unzipped_folder = ''

  desc 'Generate the Protos'
  task :generate, [:release, :github_archive_url, :output_dir] do |task, args|
    args.with_defaults(:output_dir => DEFAULT_OUTPUT_DIR)
    abort("Error: No Release Specified\n\n" + help_text) if args[:release].nil?
    abort("Error: wrong output folder format #{args[:output_dir]} requires trailing /") unless args[:output_dir][-1].eql?('/')


    destination_path = DEFAULT_DOWNLOAD_DIR + args[:release] + TAR_EXT
    download_url = args[:github_archive_url] + args[:release] + TAR_EXT

    Dir.mkdir(DEFAULT_DOWNLOAD_DIR) unless Dir.exist?(DEFAULT_DOWNLOAD_DIR)
    Rake::Task['ruby_proto_compiler:download_tar'].invoke(destination_path, download_url)
    Rake::Task['ruby_proto_compiler:unzip'].invoke(destination_path, download_url)
    Rake::Task['ruby_proto_compiler:compile_protos'].invoke(args[:output_dir])
    Rake::Task['ruby_proto_compiler:include_protos'].invoke(args[:output_dir]) if defined?(Rails)
  end

  task :include_protos, [:output_dir] do |t, args|
    puts "Adding initializers/protobufs.rb file"
    File.open(Rails.root.join('config/initializers/protobufs.rb'), 'w') do |f|
      f.puts('Dir["#{Rails.application.config.root}/' + "#{args[:output_dir]}" + '*/*.rb"].each { |file| require file }')
    end
  end

  task :download_tar, [:dest_folder, :download_url] do |t, args|
    begin
      Zlib::GzipWriter.open(args[:dest_folder]) do |local_file|
        open(args[:download_url]) do |remote_file|
          puts "Downloading TAR: #{args[:download_url]}"
          local_file.write(Zlib::GzipReader.new(remote_file).read)
        end
      end
    rescue OpenURI::HTTPError => e
      File.delete(args[:dest_folder])
      abort "Error: downloading tar with this URL: #{args[:download_url]} caused this error: #{e}"
    end
    puts "Succesfully download the TAR file found here: #{args[:dest_folder]}"
  end

  task :unzip, [:tar_path] do |t, args|
    puts "Unzipping tar at #{args[:tar_path]}"
    unzipped_folders = []

    Gem::Package::TarReader.new( Zlib::GzipReader.open(args[:tar_path])) do |tar|
      dest = nil
      tar.each do |entry|
        if entry.full_name == TAR_LONGLINK
          dest = File.join(DEFAULT_DOWNLOAD_DIR, entry.read.strip)
          next
        end
        dest ||= File.join DEFAULT_DOWNLOAD_DIR, entry.full_name
        if entry.directory?
          unzipped_folders << dest.gsub('tmp/', '')
          FileUtils.rm_rf dest unless File.directory? dest
          FileUtils.mkdir_p dest, :mode => entry.header.mode, :verbose => false
        elsif entry.file?
          FileUtils.rm_rf dest unless File.file? dest
          File.open dest, "wb" do |f|
            f.print entry.read
          end
          FileUtils.chmod entry.header.mode, dest, :verbose => false
        elsif entry.header.typeflag == '2' #Symlink!
          File.symlink entry.header.linkname, dest
        end
        dest = nil
      end
    end
    puts "Finished unzipping tar at #{args[:tar_path]}"
    @unzipped_folder = unzipped_folders.first.chomp('/')
  end

  task :compile_protos, [:output_dir] do |t, args|
    puts 'Generating Protos'
    FileUtils.mkdir_p(args[:output_dir])
    system("protoc tmp/#{@unzipped_folder}/*/*.proto --ruby_out=#{args[:output_dir]} -I tmp/#{@unzipped_folder}")
  end

  def help_text
    <<~HEREDOC
      Usage: rake ruby_proto_compiler:generate[release, github_archive_url, output_dir]
      output_dir (default) -> #{DEFAULT_OUTPUT_DIR}
    HEREDOC
  end
end