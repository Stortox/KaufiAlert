/// Product categories used to filter offers throughout the app.
///
/// The [name] of each value (e.g. `fruitAndVegetables`) is also the value
/// stored in [Product.category], so filtering can compare them directly.
enum FilterType {
  all,
  fruitAndVegetables,
  meatAndPoultry,
  fish,
  dairyProducts,
  frozenFood,
  cannedGoods,
  stapleFoods,
  coffeeTeaSweetsSnacks,
  beverages,
  bakery,
  organic,
}

/// Display labels for category filter chips, in UI order.
const List<({String label, FilterType type})> kCategoryFilters = [
  (label: 'All', type: FilterType.all),
  (label: 'Fruits & Vegetables', type: FilterType.fruitAndVegetables),
  (label: 'Meat & Poultry', type: FilterType.meatAndPoultry),
  (label: 'Fish', type: FilterType.fish),
  (label: 'Dairy', type: FilterType.dairyProducts),
  (label: 'Frozen Food', type: FilterType.frozenFood),
  (label: 'Canned Goods', type: FilterType.cannedGoods),
  (label: 'Staple Foods', type: FilterType.stapleFoods),
  (label: 'Coffee, Tea, Sweets & Snacks', type: FilterType.coffeeTeaSweetsSnacks),
  (label: 'Beverages', type: FilterType.beverages),
  (label: 'Bakery', type: FilterType.bakery),
  (label: 'Organic', type: FilterType.organic),
];
