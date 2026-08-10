Account.find_each do |account|
  Category::DEFAULT_CATEGORIES.each do |cat_name|
    account.categories.find_or_create_by!(name: cat_name) do |cat|
      cat.default = true
    end
  end

  CostCenter::DEFAULT_COST_CENTERS.each do |cc_name|
    account.cost_centers.find_or_create_by!(name: cc_name) do |cc|
      cc.default = true
    end
  end
end
