require_relative 'lib/ruby_proto_compiler/version'

Gem::Specification.new do |s|
  s.name        = 'ruby_proto_compiler'
  s.version     = RubyProtoCompiler::VERSION
  s.date        = '2019-09-09'
  s.summary     = 'A protobuf generator for your protobufs'
  s.description = 'Exposes a rake task that easily imports protobufs into your Rails apps'
  s.authors     = ["Jonathan Yeong"]
  s.email       = 'hello@jonathanyeong.com'
  s.files       = `git ls-files`.split("\n")

  s.require_paths = ['lib']

  s.required_ruby_version = '~> 2.6'

  s.add_runtime_dependency 'rake'
end