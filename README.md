# Ruby Proto Compiler Gem

This Gem provides a rake task that will add compiled protobuf files to your project. You can use these
for your Rails apps or plain Ruby apps.

## Requirements

Install protoc - to compile the protobufs.

```bash
brew install protobuf
```

## Getting Started

### Install

Add this to your Gemfile.

```ruby
gem 'ruby_proto_compiler'
```

To check that it works run:

```bash
rake -T
```

You should see this as one of the rake tasks:

```bash
rake ruby_proto_compiler:generate[release,github_archive_url,output_dir]  # Generate the Protos
```

### Usage

If you use Rails you will not need to configure anything. If you want to import this rake task to a
plain Ruby project you will need to add this to your Rakefile (see the example/ project).

```ruby
require 'ruby_proto_compiler'

load 'ruby_proto_compiler/task/gen_protos.rake'
```

To run the rake task:

```bash
bundle exec rake ruby_proto_compiler:generate['<release-version>','https://github.com/<project-archive-url>','<output-dir>']
```

**NOTE:** `output-dir` will default to your `lib/messages/` folder.

Running this rake task will download the `tar.gz` of the release from the github url. It will unpack that tar in a `tmp/` folder.
Then it will compile the protobuf files and place them in the `lib/messages/` folder. It will then generate an initializer file to require your protobufs.

### Troubleshooting

If you're getting this error on Zshell:

```bash
$ bundle exec rake ruby_proto_compiler:generate["1.0.0"]
# zsh: no matches found: ruby_proto_compiler:generate[1.0.0]
```

You will need to escape the square brackets with `\`:

```bash
bundle exec rake ruby_proto_compiler:generate\["1.0.0"\]
```

## Future Roadmap

- Add ability to filter top level packages to compile.
- Expose other rake tasks so you can perform each step independently.
- Better rake output.
