class DatabaseAnonymizer

  $arel_silence_type_casting_deprecation = true

  CLASSES_TO_ANONYMISE = [ Case::Base, User, CaseTransition ]

  def initialize(filename)
    @filename = File.expand_path(filename)
    @batch_size = 1_000
  end

  def run
    CLASSES_TO_ANONYMISE.each { |klass| anonymise_class(klass) }
  end

  private

  def anonymise_class(klass)
    File.open(@filename, 'a') do |fp|
      klass.find_each(batch_size: @batch_size) do |object|
        insert_statement = if object.is_a?(Case::Base)
                             kase = anonymize_case(object)
                             insert_stmt(kase, attrs_without_properties(kase))
                           elsif object.is_a?(User)
                             user = anonymize_user(object)
                             insert_stmt(user, user.attribute_names)
                           elsif object.is_a?(CaseTransition)
                             ct = anonymise_case_transition(object)
                             insert_stmt(ct, attrs_without_metadata(ct))
                           else
                             raise "Unexpected object #{object.class}"

                           end
        fp.puts insert_statement
      end
    end
  end

  def attributes_with_values(model, attribute_names)
    attrs = {}
    arel_table = model.class.arel_table

    attribute_names.each do |name|
      attrs[arel_table[name]] = model._read_attribute(name)
    end
    attrs
  end

  def cast_value_types_for_db(values, casting_type)
    type_caster = casting_type.arel_table.send(:type_caster)
    values.each do |attribute, value|
      values[attribute] = type_caster.type_cast_for_database(attribute.name, value)
    end
    values
  end

  def insert_stmt(anon_object, attributes)
    anon_object.class.arel_table.create_insert.tap { |im|
      values = attributes_with_values(anon_object, attributes)

      im.insert(cast_value_types_for_db(values, anon_object.class))
    }.to_sql + ';'
  end

  def attrs_without_properties(object)
    object.attribute_names - object.properties.keys
  end

  def attrs_without_metadata(object)
    object.attribute_names - object.metadata.keys
  end

  def anonymize_user(user)
    unless user.email =~ /@digital.justice.gov.uk$/
      user.full_name = Faker::Name.unique.name
      user.email = Faker::Internet.email(name: user.full_name)
    end
    user
  end

  def anonymize_case(kase)
    kase.name = Faker::Name.name
    kase.email = Faker::Internet.email(name:kase.name)
    kase.subject = initial_letters(kase.subject) + Faker::Company.catch_phrase
    kase.message = Faker::Lorem.paragraph
    kase.postal_address = fake_address unless kase.postal_address.blank?
    kase.subject_full_name = kase.name
    kase
  end

  def anonymise_case_transition(ct)
    ct.message = initial_letters(ct.message) + "\n\n" + Faker::Lorem.paragraph unless ct.message.nil?
    ct
  end

  def initial_letters(phrase)
    words = phrase.split(' ')
    "[#{words[0..9].map{ |w| w.first.upcase }.join('')}]"
  end

  def fake_address
    [
        Faker::Address.street_address,
        Faker::Address.city,
        Faker::Address.state,
        Faker::Address.zip
    ].join("\n")
  end
end
