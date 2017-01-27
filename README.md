# driving-bot

> Driving a driving website with ruby.

Very much a hack in progress.

## Install

```
bundle install
```

### Dependencies
Gemfile and `.ruby-version` specify ruby-2.4.0.

Unfortunately, mechanize gem has non-trivial dependencies on nokogiri, which in turn depends on libxml. Bundler should take care of installation, but your system still has to be able to build/run nokogiri.

## Usage
If you `cp .env.example .env` and supply the driving website's credentials inside:

```
ruby driving-bot.rb
```

Otherwise, either export the environment variables in your shell, or simply supply them with the command.

## Contribute

Make a PR.

## License

See [LICENSE.md](LICENSE.md).
