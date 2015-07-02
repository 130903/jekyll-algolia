require 'algoliasearch'
require 'nokogiri'
require 'json'
require_relative './record_extractor.rb'

# `jekyll algolia push` command
class AlgoliaSearchJekyllPush < Jekyll::Command
  class << self
    attr_accessor :options, :config

    def init_with_program(_prog)
    end

    # Init the command with options passed on the command line
    # `jekyll algolia push ARG1 ARG2 --OPTION_NAME1 OPTION_VALUE1`
    # config comes from _config.yml
    def init_options(args = [], options = {}, config = {})
      args = [] unless args
      @args = args
      @options = options
      @config = config

      # Allow for passing index name on the command line
      index_name = args[0]
      @config['algolia']['index_name'] = index_name if index_name
      self
    end

    # Check if the specified file should be indexed (we exclude static files,
    # robots.txt and custom defined exclusions).
    def indexable?(file)
      return false if file.is_a?(Jekyll::StaticFile)

      # Keep only markdown and html files
      allowed_extensions = %w(html)
      if @config['markdown_ext']
        allowed_extensions += @config['markdown_ext'].split(',')
      end
      current_extension = File.extname(file.name)[1..-1]
      return false unless allowed_extensions.include?(current_extension)

      # Exclude files manually excluded from config
      excluded_files = @config['algolia']['excluded_files']
      unless excluded_files.nil?
        return false if excluded_files.include?(file.name)
      end

      true
    end

    def process
      site = Jekyll::Site.new(@config)

      # We overwrite the site.write command so instead of writing files to disks
      # we'll parse them and push them to Algolia
      def site.write
        items = []
        each_site_file do |file|
          next unless AlgoliaSearchJekyllPush.indexable?(file)

          new_items = AlgoliaSearchRecordExtractor.new(file).extract
          next if new_items.nil?
          items += new_items
        end
        # AlgoliaSearchJekyllPush.push(items)
      end

      # This will call the build command by default, which will in turn call our
      # custom .write method
      site.process
    end

    # def check_credentials(api_key, application_id, index_name)
    #   unless api_key
    #     Jekyll.logger.error 'Algolia Error: No API key defined'
    #     Jekyll.logger.warn '  You have two ways to configure your API key:'
    #     Jekyll.logger.warn '    - The ALGOLIA_API_KEY environment variable'
    #     Jekyll.logger.warn '    - A file named ./_algolia_api_key in your '\
    #                        'source folder'
    #     exit 1
    #   end

    #   unless application_id
    #     Jekyll.logger.error 'Algolia Error: No application ID defined'
    #     Jekyll.logger.warn '  Please set your application id in the '\
    #                        '_config.yml file, like so:'
    #     puts ''
    #     # The spaces are needed otherwise the text is centered
    #     Jekyll.logger.warn '  algolia:         '
    #     Jekyll.logger.warn '    application_id: \'{your_application_id}\''
    #     puts ''
    #     Jekyll.logger.warn '  Your application ID can be found in your algolia'\
    #                        ' dashboard'
    #     Jekyll.logger.warn '    https://www.algolia.com/licensing'
    #     exit 1
    #   end

    #   unless index_name
    #     Jekyll.logger.error 'Algolia Error: No index name defined'
    #     Jekyll.logger.warn '  Please set your index name in the _config.yml'\
    #                        ' file, like so:'
    #     puts ''
    #     # The spaces are needed otherwise the text is centered
    #     Jekyll.logger.warn '  algolia:         '
    #     Jekyll.logger.warn '    index_name: \'{your_index_name}\''
    #     puts ''
    #     Jekyll.logger.warn '  You can edit your indices in your dashboard'
    #     Jekyll.logger.warn '    https://www.algolia.com/explorer'
    #     exit 1
    #   end
    #   true
    # end

    # def configure_index(index)
    #   default_settings = {
    #     typoTolerance: true,
    #     attributeForDistinct: 'url',
    #     attributesForFaceting: %w(tags type),
    #     attributesToIndex: %w(
    #       title h1 h2 h3 h4 h5 h6
    #       unordered(text)
    #       unordered(tags)
    #     ),
    #     attributesToRetrieve: %w(
    #       title h1 h2 h3 h4 h5 h6
    #       posted_at
    #       content
    #       text
    #       url
    #       css_selector
    #     ),
    #     customRanking: ['desc(posted_at)', 'desc(title_weight)'],
    #     distinct: true,
    #     highlightPreTag: '<span class="algolia__result-highlight">',
    #     highlightPostTag: '</span>'
    #   }
    #   custom_settings = {}
    #   @config['algolia']['settings'].each do |key, value|
    #     custom_settings[key.to_sym] = value
    #   end
    #   settings = default_settings.merge(custom_settings)

    #   index.set_settings(settings)
    # end



    def get_items_from_file(file)
      get_paragraphs_from_html(html, base_data)
    end


    # Get the list of headings (h1, h2, etc) above the specified node
    def get_previous_hx(node, memo = { level: 7 })
      previous = node.previous_element
      # No previous element, we go up to the parent
      unless previous
        parent = node.parent
        # No parent, we stop
        if parent.name == 'body'
          memo.delete(:level)
          return memo
        end
        # We start from the previous sibling of the parent
        return get_previous_hx(parent, memo)
      end

      # Skip non-title elements
      tag_name = previous.name
      possible_title_elements = %w(h1 h2 h3 h4 h5 h6)
      unless possible_title_elements.include?(tag_name)
        return get_previous_hx(previous, memo)
      end

      # Skip if item already as title of a higher level
      title_level = tag_name.gsub('h', '').to_i
      return get_previous_hx(previous, memo) if title_level >= memo[:level]
      memo[:level] = title_level

      # Add to the memo and continue
      memo[tag_name.to_sym] = previous.content
      get_previous_hx(previous, memo)
    end

    # Get a custom value representing the number of word occurence from the
    # titles into the content
    def get_title_weight(content, item)
      # Get list of words
      words = %i(title h1 h2 h3 h4 h5 h6)
              .select { |title| item.key?(title) }
              .map { |title| item[title].split(/\W+/) }
              .flatten
              .compact
              .uniq
      # Count how many words are in the text
      weight = 0
      words.each { |word| weight += 1 if content.include?(word) }
      weight
    end

    # Will get a unique css selector for the node
    def get_css_selector(node)
      node.css_path.gsub('html > body > ', '')
    end

    # Will get the unique heading hierarchy to this item
    def get_heading_hierarchy(item)
      headings = %w(title h1 h2 h3 h4 h5 h6)
      headings.map { |heading| item[heading.to_sym] }.compact.join(' > ')
    end

    # Get a list of items representing the different paragraphs
    def get_paragraphs_from_html(html, base_data)
      doc = Nokogiri::HTML(html)
      paragraphs = []
      doc.css('p').each_with_index do |p, index|
        next unless p.text.size > 0
        new_item = base_data.clone
        # new_item.merge!(get_previous_hx(p))
        new_item[:objectID] = "#{new_item[:slug]}_#{index}"
        # new_item[:raw_html] = p.to_s
        # new_item[:text] = p.content.gsub('<', '&lt;').gsub('>', '&gt;')
        # new_item[:hierarchy] = get_heading_hierarchy(new_item)
        new_item[:css_selector] = get_css_selector(p)
        new_item[:title_weight] = get_title_weight(p.text, new_item)
        paragraphs << new_item
      end
      paragraphs
    end

    def push(items)
      api_key = AlgoliaSearchJekyll.api_key
      application_id = @config['algolia']['application_id']
      index_name = @config['algolia']['index_name']
      check_credentials(api_key, application_id, index_name)

      Algolia.init(application_id: application_id, api_key: api_key)
      index = Algolia::Index.new(index_name)
      configure_index(index)
      index.clear_index

      items.each_slice(1000) do |batch|
        Jekyll.logger.info "Indexing #{batch.size} items"
        begin
          index.add_objects(batch)
        rescue StandardError => error
          Jekyll.logger.error 'Algolia Error: HTTP Error'
          Jekyll.logger.warn error.message
          exit 1
        end
      end

      Jekyll.logger.info "Indexing of #{items.size} items " \
                         "in #{index_name} done."
    end
  end
end
