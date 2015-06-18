# Algolia Jekyll Plugin

Jekyll plugin to automatically index your Jekyll posts and pages into an
Algolia index.

## Usage

```shell
$ jekyll algolia push
```

This will push the content of your jekyll website to your Algolia index.

## Installation

First, add the `algoliasearch-jekyll` gem to your `Gemfile`, in the
`:jekyll_plugins` section. If you do not yet have a `Gemfile`, here is the
minimum content to get your started.

```ruby
source 'https://rubygems.org'

gem 'jekyll', '>=2.5.3'

group :jekyll_plugins do
  gem 'algoliasearch-jekyll'
end
```

Once this is done, download all dependencies with `bundle install`. 

Then, add `algoliasearch-jekyll` to your `_config.yml` file, under the `gems`
section, like this:

```yaml
gems:
  - algoliasearch-jekyll
```

If everything went well, you should be able to execute `jekyll help` and see the
`algolia` subcommand listed.

## Configuration

Add information about your Algolia configuration into the `_config.yml` file,
under the `algolia` section, like this:

```yaml
algolia:
  application_id: 'your_application_id'
  index_name:     'your_index_name'
```

You api key will be read either from the `ALGOLIA_API_KEY` environment variable,
or the `./_algolia_api_key` file.

Note that if you decide to use the `./_algolia_api_key` approach, we strongly
encourage you to not track this file in your versionning system.


## GitHub Pages

Unfortunatly, GitHub does not allow custom plugins to be run on GitHub Pages.
This means that you will have to manually run `jekyll algolia push` before
pushing your content to GitHub.

## Search

Now that your index is populated with your data, you can start searching in it.
You can query it yourself using our [Javascript client][1], or you can use
our updated [Hyde theme][2].


[1]: https://www.algolia.com/doc/javascript
[2]: https://github.com/algolia/algoliasearch-jekyll-hyde
