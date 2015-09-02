class Subject < ActiveRecord::Base
  has_many :subject_tag_mappers
  has_many :tags, through: :subject_tag_mappers
end
