module VideoChannelOutJsonValidation
  
  include JsonCompletenessChecker

  def self.included base
    base.extend ClassMethods
    base.class_eval do
      scope :with_valid_json, -> { where(out_json_valid: true) }      
    end
  end

  CONTENT_LIST_CHANNEL_STRUCTURE = [
    'id',
    'url',
    'title',
    'description',
    'thumbnails' => ['30x30', '51x51', '60x60', '75x75', '90x90', '102x102', '120x120', '150x150', '180x180', '240x240']
  ]

  module ClassMethods

    def check_json_validity
      find_in_batches(batch_size: 20) {|group|
        group.each {|ch|
          ch.mark_out_json_validity
        }
      }
    end

  end

  def mark_out_json_validity options = {}
    to_save = options[:save]
    to_save = true if to_save.nil?
    
    result = verify_content_list_json_structure
    json_valid = result[:success]

    if json_valid
      if to_save
        update_columns(out_json_valid: true) 
      else
        self.out_json_valid = true
      end
    else
      if to_save
        update_columns(out_json_valid: false) 
      else
        self.out_json_valid = false
      end
    end
  end

  def verify_content_list_json_structure
    @for_json ||= for_json
    verify_json_structure @for_json, CONTENT_LIST_CHANNEL_STRUCTURE
  end

end