# encoding: UTF-8

require "spec_helper"

describe "rich snippets de evento", search: true do
  before do
    I18n.locale = :pt
    Time.zone = -2
    Timecop.travel Date.new(2012, 12, 11)

    user   = Fabricate :user
    venue  = Fabricate :venue
    @event = Fabricate :event, starts_at: DateTime.new(2012, 12, 11, 10, 30, 50, "-2"), venue: venue

    controller.stub(:current_user) { user }
    view.stub(:venue) { venue }
    view.stub_chain(:venue, :is_ar_livre?) { true }
    view.stub(:event) { @event }

    render(template: "events/show", locals: { event: @event, venue: venue })
  end

  after do
    Time.zone = Time.zone_default
    I18n.locale = I18n.default_locale
  end

  subject { Capybara::Node::Simple.new(rendered) }

  # Rich Snippet - scope - obrigatório
  # Indicates that the item is an Event
  it { should have_css('#pz-event[itemscope]') }
  it { should have_css('#pz-event[itemtype="http://data-vocabulary.org/Event"]') }

  # Rich Snippet - summary - obrigatório
  # The name of the event.
  it { should have_selector('[itemprop="summary"]', text: @event.name) }

  # Rich Snippet - startDate - obrigatório
  # The starting date and time of the event in ISO date format, "2012-12-11T10:30:50-02:00".
  it { should have_css("[itemprop='startDate']") }
  it { should have_css("time[datetime='2012-12-11T10:30:50-02:00']") }

  # Rich Snippet - location - obrigatório para evento único (não um grupo)
  # The location or venue of the event
  it { should have_css("[itemprop='location']") }

  # Rich Snippet - location - obrigatório para evento único (não um grupo)
  # The location or venue of the event
  it { should have_css("figure.main_image img[itemprop='photo']") }
  it { should have_css("figure.main_image img[src='#{@event.photo.thumb("480x333#").url}']") }

  # Rich Snippet - description
  it { should have_css('[itemprop="description"]', text: @event.description) }

  # Rich Snippet - eventType
  it { should have_css('[itemprop="eventType"]', text: @event.event_type.name.singularize) }
end
