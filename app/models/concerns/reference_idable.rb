module ReferenceIdable
  extend ActiveSupport::Concern

  included do
    before_validation :set_reference_id

    # attr_writer :provisional_reference_id
  end

  # # NOTE: Make this better
  # def provisional_reference_id
  #   @provisional_reference_id ||= reference_id if id.present?
  #   @provisional_reference_id ||= "A1"
  # end

  def set_reference_id
    # THE Dream is that this will be easier and shorter than integer ids
    # something like A1
    # ALSO - it will start at 0 if the object is always associated with something
    # ie Argument will have an id uniq to the hypothesis
    self.reference_id ||= id
  end
end
