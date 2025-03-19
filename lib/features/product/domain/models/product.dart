class Product {
  Product({
    this.id,
    required this.name,
    required this.description,
    required this.quantity,
  });

  String? id;
  String name;
  String description;
  int quantity;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json["entry_id"],
        name: json["data"]["name"] ?? "---",
        description: json["data"]["description"] ?? "---",
        quantity: json["data"]["quantity"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "entry_id": id ?? "0",
        "name": name,
        "description": description,
        "quantity": quantity,
      };

  Map<String, dynamic> toJsonNoId() => {
        "name": name,
        "description": description,
        "quantity": quantity,
      };

  @override
  String toString() {
    return 'User{entry_id: $id, name: $name, description: $description, quantity: int.parse($quantity)}';
  }
}
