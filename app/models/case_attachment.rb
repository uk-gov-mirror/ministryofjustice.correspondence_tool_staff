# == Schema Information
#
# Table name: case_attachments
#
#  id         :integer          not null, primary key
#  case_id    :integer
#  type       :enum
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CaseAttachment < ActiveRecord::Base
  self.inheritance_column = :_type_not_used
  belongs_to :case

  validates :type, presence: true
  validate :check_file_type

  enum type: { response: 'response' }

  def check_file_type
    filename = File.basename URI.parse(url).path
    mime_type = Rack::Mime.mime_type(File.extname filename)
    unless Settings.case_uploads_accepted_types.include? mime_type
      errors[:url] << I18n.t(
        'activerecord.errors.models.case_attachment.attributes.url.bad_file_type',
        type: mime_type,
        name: File.basename(URI.parse(url).path)
      )
    end
  end
end
