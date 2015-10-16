class ListPopupForm
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  validates :description, presence: true, if: :creating_list

  delegate :errors, to: :item_list

  def persisted?
    false
  end

  def item_list
    @item_list ||= ItemList.new
  end

  def list
    item_list.list
  end

  def build_list attributes
    if (attributes.has_key? "list_id") && (attributes["list_id"] != "")
      item_list.list = List.find(attributes["list_id"])
    else
      item_list.build_list name: attributes["name"]
      item_list.list.user = current_user
    end
  end

  def submit params
    build_list params["item_list"].slice("name", "list_id")
    item_list.attributes = params["item_list"].slice("description", "item_type", "item_id")

    if list.valid?
      list.save!
      true
    else
      false
    end
  end

  def errors
    list.errors
  end
end
