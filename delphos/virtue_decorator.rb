class VirtueDecorator < Draper::Decorator
  delegate_all

  def description
    if source.description.present?
      h.markdown source.description
    end
  end

  def short_description
    if source.description.present?
      formatted = h.simple_format(source.description)
      h.markdown Nokogiri::HTML.parse(formatted).css('p').try(:first).try(:text)
    end
  end

  def long_description
    if source.description.present?
      formatted = h.simple_format(source.description)
      h.markdown(
        Nokogiri::HTML.parse(formatted).css('p').try(:slice, 1..-1).map(&:text).join("\n")
      )
    end
  end
end
