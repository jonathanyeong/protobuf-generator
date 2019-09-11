require_relative 'lib/protobuf_generator/version'

Gem::Specification.new do |s|
  s.name        = 'protobuf_generator'
  s.version     = ProtobufGenerator::VERSION
  s.date        = '2019-09-09'
  s.summary     = 'A protobuf generator for your protobufs'
  s.description = 'Exposes a rake task that easily imports protobufs into your Rails apps'
  s.authors     = ["Jonathan Yeong"]
  s.email       = 'hello@jonathanyeong.com'
  s.files       = ["lib/protobuf_generator.rb"]

  s.require_paths = ['lib']

  s.required_ruby_version = '~> 2.6'

  s.add_dependency 'rake'
end