Rails.application.config.after_initialize do
  table_tags  = %w[table thead tbody tfoot tr th td colgroup col caption]
  table_attrs = %w[colspan rowspan scope headers]

  ActionText::ContentHelper.allowed_tags =
    Rails::HTML4::SafeListSanitizer.allowed_tags +
    [ActionText::Attachment.tag_name, "figure", "figcaption"] +
    table_tags

  ActionText::ContentHelper.allowed_attributes =
    Rails::HTML4::SafeListSanitizer.allowed_attributes +
    ActionText::Attachment::ATTRIBUTES +
    table_attrs
end
