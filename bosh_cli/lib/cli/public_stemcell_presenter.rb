require 'cli/public_stemcell_index'
require 'cli/download_with_progress'

module Bosh::Cli
  class PublicStemcellPresenter
    def initialize(ui, public_stemcell_index)
      @ui = ui
      @public_stemcell_index = public_stemcell_index
    end

    def list(options)
      full = !!options[:full]
      stemcells_table = @ui.table do |t|
        t.headings = full ? %w(Name Url) : %w(Name)

        stemcell_for(options).each do |stemcell|
          t << (full ? [stemcell.name, stemcell.url] : [stemcell.name])
        end
      end

      @ui.say(stemcells_table.render)
      @ui.say("To download use `bosh download public stemcell <stemcell_name>'. For full url use --full.")
    end

    def download(stemcell_name)
      unless @public_stemcell_index.has_stemcell?(stemcell_name)
        @ui.err("'#{stemcell_name}' not found in '#{@public_stemcell_index.names.join(',')}'.")
      end

      if File.exists?(stemcell_name) && !@ui.confirmed?("Overwrite existing file `#{stemcell_name}'?")
        @ui.err("File `#{stemcell_name}' already exists")
      end

      stemcell = @public_stemcell_index.find(stemcell_name)
      download_with_progress = DownloadWithProgress.new(stemcell.size, stemcell.url)
      download_with_progress.perform

      if download_with_progress.sha1?(stemcell.sha1)
        @ui.say('Download complete'.make_green)
      else
        @ui.err("The downloaded file sha1 `#{download_with_progress.sha1}' does not match the expected sha1 `#{stemcell.sha1}'")
      end
    end

    private

    def stemcell_for(options)
      options[:all] ? @public_stemcell_index.all : @public_stemcell_index.stable
    end
  end
end