require 'prawn'

require 'pry'

module Deliver
  class PdfGenerator

    # TODO: Docs
    def render(deliverer, export_path = nil)
      export_path ||= '/tmp'
      
      pdf = Prawn::Document.new(:margin => [0,0,0,0])
      
      resulting_path = "#{export_path}/#{Time.now.to_i}.pdf"
      Prawn::Document.generate(resulting_path) do

        deliverer.app.metadata.information.each do |language, content|
          # info = deliverer.deploy_information
          title = content[:title][:value] rescue '' # TODO: that shouldn't happen

          Helper.log.info("Exporting locale '#{language}' for app with title '#{title}'")

          font_size 20
          text "#{language}: #{title}"
          stroke_horizontal_rule
          font_size 14

          move_down 30



          col1 = 200
          modified_color = '0000AA'
          standard_color = '000000'


          prev_cursor = cursor.to_f
          # Description on right side
          bounding_box([col1, cursor], width: 340.0) do
            if content[:description] and content[:description][:value]
              text content[:description][:value], size: 6, color: (content[:description][:modified] ? modified_color : standard_color)
            end
            move_down 10
            stroke_horizontal_rule
            move_down 10
            text "Changelog:", size: 8
            move_down 5
            if content[:version_whats_new] and content[:version_whats_new][:value]
              text content[:version_whats_new][:value], size: 6, color: (content[:version_whats_new][:modified] ? modified_color : standard_color)
            end
          end
          title_bottom = cursor.to_f

          move_cursor_to prev_cursor


          all_keys = [:support_url, :privacy_url, :software_url, :keywords]

          all_keys.each_with_index do |key, index|
            value = content[key][:value] rescue nil
            
            color = (content[key][:modified] ? modified_color : standard_color rescue standard_color)

            bounding_box([0, cursor], width: col1) do
              key = key.to_s.gsub('_', ' ').capitalize
              text "#{key}: #{value}", color: color, width: 200, size: 12
            end
          end

          image_width = 60
          padding = 10
          last_size = nil
          top = [cursor, title_bottom].min - padding
          index = 0
          previous_image_height = 0
          if content[:screenshots]
            content[:screenshots].sort{ |a, b| a.screen_size <=> b.screen_size }.each do |screenshot|
              
              if last_size and last_size != screenshot.screen_size
                # Next row (other simulator size)
                top -= (previous_image_height + padding)
                index = 0
              end

              image screenshot.path, width: image_width, 
                                        at: [(index * (image_width + padding)), top]

              original_size = FastImage.size(screenshot.path)
              previous_image_height = (image_width.to_f / original_size[0].to_f) * original_size[1].to_f

              last_size = screenshot.screen_size
              index += 1
            end
          end

          start_new_page
        end
      end

      return resulting_path
    end
  end
end