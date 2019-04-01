module VideoOutJsonValidation

  include JsonCompletenessChecker
  include VideoPresenters::Json

  def self.included base
    base.extend ClassMethods
    base.class_eval do
      scope :with_valid_json, -> { where(out_json_valid: true) }
    end
  end

  VIDEO_LATEST_JSON_STRUCTURE = [
    'id', 
    'url', 
    'title', 
    'description', 
    'published_at', 
    'views', 
    'likes', 
    'dislikes',
    'thumbnails' => ['1280x720', '220x124', '275x155', '314x176', '440x248', '528x297', '568x320'],
    'channel' => [
              'id', 
              'title',
              'humbnails' => ["30x30", "51x51", "60x60", "75x75", "90x90", '102x102', '120x120', '150x150', '180x180', '240x240']
             ]
  ]

  VIDEO_LATEST_JSON_WITHOUT_CHANNEL_STRUCTURE = [
    'id', 
    'url', 
    'title', 
    'description', 
    'published_at', 
    'views', 
    'likes', 
    'dislikes',
    'thumbnails' => ['1280x720', '220x124', '275x155', '314x176', '440x248', '528x297', '568x320']
  ]

  CHANNEL_LIST_VIDEO_STRUCTURE = [
    'id',
    'url', 
    'title',
    'description',
    'published_at',
    'views',
    'likes',
    'dislikes',
    'thumbnails' => ["1280x720", "220x124", "275x155", "314x176", "440x248", "528x297", "568x320"]
  ]

  module ClassMethods

    def check_json_validity
      find_in_batches(batch_size: 20) {|group|
        group.each {|v|
          # puts "Checking: #{v.identifier}, channel: #{v.video_channel_id}"
          v.mark_out_json_validity
        }
      }
    end

  end

  def mark_out_json_validity options = {}
    to_save = options[:save]
    to_save = true if to_save.nil?

    validation_results = {}

    json_valid = true

    result = verify_latest_video_json_structure
    json_valid &&= result[:success]

    validation_results[:verify_latest_video_json_structure] = result
    if json_valid
      result = verify_channel_list_video_json_structure
      json_valid &&= result[:success]
      validation_results[:verify_channel_list_video_json_structure] = result
    end

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

    validation_results
  end

  def verify_latest_video_json_structure
    # verify_json_structure construct_latest_json, 
    #                       self.video_channel_id.nil? ? VIDEO_LATEST_JSON_WITHOUT_CHANNEL_STRUCTURE : VIDEO_LATEST_JSON_STRUCTURE
    verify_json_structure construct_latest_json, VIDEO_LATEST_JSON_STRUCTURE
  end

  def verify_channel_list_video_json_structure
    @for_json ||= video_json self
    verify_json_structure @for_json, CHANNEL_LIST_VIDEO_STRUCTURE
  end

  private 

  def construct_latest_json
    @for_json ||= video_json self
    video_data = @for_json
    video_data = self.class.attach_channel_data video_data, self.channel
    video_data
  end

end