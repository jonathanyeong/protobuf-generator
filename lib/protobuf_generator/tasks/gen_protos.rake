# frozen_string_literal: true
require 'open-uri'
require 'rubygems/package'
require 'zlib'

TAR_LONGLINK = '././@LongLink'  # http://dracoater.blogspot.com/2013/10/extracting-files-from-targz-with-ruby.html
TAR_EXT = '.tar.gz'.freeze
DEFAULT_ARCHIVE_URL = 'https://git.enova.com/brazil/schema_registry/archive/'.freeze
DEFAULT_OUTPUT_DIR = 'app/messages/'.freeze
DEFAULT_DOWNLOAD_DIR = 'tmp/'

namespace :_protobufs do
  @unzipped_folder = ''

  desc 'Generate the Protos'
  task :generate, [:release, :github_archive_url, :output_dir] do |task, args|
    abort("Error: No Release Specified\n\n" + help_text) if args[:release].nil?
    args.with_defaults(:github_archive_url => DEFAULT_ARCHIVE_URL)
    args.with_defaults(:output_dir => DEFAULT_OUTPUT_DIR)

    destination_path = DEFAULT_DOWNLOAD_DIR + args[:release] + TAR_EXT
    download_url = args[:github_archive_url] + args[:release] + TAR_EXT

    Dir.mkdir(DEFAULT_DOWNLOAD_DIR) unless Dir.exist?(DEFAULT_DOWNLOAD_DIR)
    Rake::Task['enova_protobufs:download_tar'].invoke(destination_path, download_url)
    Rake::Task['enova_protobufs:unzip'].invoke(destination_path, download_url)
    Rake::Task['enova_protobufs:compile_protos'].invoke(args[:output_dir])
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
      Usage: rake enova_protobufs:generate[release, github_archive_url, output_dir]
      github_archive_url (default) -> #{DEFAULT_ARCHIVE_URL}
      output_dir (default) -> #{DEFAULT_OUTPUT_DIR}
    HEREDOC
  end
end