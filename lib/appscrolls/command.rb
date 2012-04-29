require 'appscrolls'
require 'thor'

module AppScrollsScrolls
  class Command < Thor
    include Thor::Actions
    desc "new APP_NAME", "create a new Rails app"
    method_option :scrolls, :type => :array, :aliases => "-s", :desc => "List scrolls, e.g. -s resque rails_basics jquery"
    method_option :save, :desc => "Save the selection of scrolls. Usage: '--save NAME'"
    method_option :use, :desc => "Use a saved set of scrolls. Usage: '--use NAME'"
    method_option :template, :type => :boolean, :aliases => "-t", :desc => "Only display template that would be used"
    def new(name)
      if options[:scrolls]
        run_template(name, options[:scrolls], options[:template])
        save_scroll_selections if options[:save]
      elsif options[:use]
        scrolls = get_existing_saves
        run_template(name, scrolls[options[:use]], options[:template])
      else
        @scrolls = []

        while scroll = ask("#{print_scrolls}#{bold}Which scroll would you like to add? #{clear}#{yellow}(blank to finish)#{clear}")
          if scroll == ''
            run_template(name, @scrolls)
            break
          elsif AppScrollsScrolls::Scrolls.list.include?(scroll)
            @scrolls << scroll
            puts
            puts "> #{green}Added '#{scroll}' to template.#{clear}"
          else
            puts
            puts "> #{red}Invalid scroll, please try again.#{clear}"
          end
        end
      end
    end

    desc "list [CATEGORY]", "list available scrolls (optionally by category)"
    def list(category = nil)
      if category
        scrolls = AppScrollsScrolls::Scrolls.for(category).map{|r| AppScrollsScrolls::Scroll.from_mongo(r) }
      else
        scrolls = AppScrollsScrolls::Scrolls.list_classes
      end

      scrolls.each do |scroll|
        puts scroll.key.ljust(15) + "# #{scroll.description}"
      end
    end

    no_tasks do
      def cyan; "\033[36m" end
      def clear; "\033[0m" end
      def bold; "\033[1m" end
      def red; "\033[31m" end
      def green; "\033[32m" end
      def yellow; "\033[33m" end

      def print_scrolls
        puts
        puts
        puts
        if @scrolls && @scrolls.any?
          puts "#{green}#{bold}Your Scrolls:#{clear} " + @scrolls.join(", ")
          puts
        end
        puts "#{bold}#{cyan}Available Scrolls:#{clear} " + AppScrollsScrolls::Scrolls.list.join(', ')
        puts
      end

      def run_template(name, scrolls, display_only = false)
        puts
        puts
        puts "#{bold}Generating and Running Template...#{clear}"
        puts
        file = Tempfile.new('template')        
        template = AppScrollsScrolls::Template.new(scrolls)

        puts "Using the following scrolls:"
        template.resolve_scrolls.map do |scroll|
          color = scrolls.include?(scroll.new.key) ? green : yellow # yellow - automatic dependency
          puts "  #{color}* #{scroll.new.name}#{clear}"
        end
        puts

        file.write template.compile
        file.close
        if display_only
          puts "Template stored to #{file.path}"
          puts File.read(file.path)
        else
          system "rails new #{name} -m #{file.path} #{template.args.join(' ')}"
        end
      ensure
        file.unlink
      end

      def saved_scroll_filename
        File.join(ENV['HOME'], '.saved_scrolls')
      end

      def get_existing_saves
        File.exists?(saved_scroll_filename) ? YAML.load_file(saved_scroll_filename) : {}
      end

      def save_scroll_selections
        saved_scrolls = get_existing_saves
        saved_scrolls[options[:save]] = options[:scrolls]

        File.open(saved_scroll_filename, 'w') { |out| YAML.dump(saved_scrolls, out) }
      end
    end
  end
end
