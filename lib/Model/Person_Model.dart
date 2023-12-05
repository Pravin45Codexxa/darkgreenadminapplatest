import 'package:admin_eshop/Helper/String.dart';

class PersonModel {
  String? id,
      name,
      email,
      img,
      status,
      balance,
      mobile,
      city,
      area,
      street,
      cashToCollect;

  PersonModel(
      {this.id,
      this.name,
      this.email,
      this.img,
      this.status,
      this.balance,
      this.cashToCollect,
      this.mobile,
      this.city,
      this.area,
      this.street});

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json[ID],
      name: json[NAME],
      email: json[EMAIL],
      img: json[IMAGE],
      status: json[STATUS],
      mobile: json[MOBILE],
      city: json[CITY] ?? "",
      area: json[AREA] ?? "",
      street: json[STREET] ?? "",
      balance: json[BALANCE],
      cashToCollect: json[CASH_TO_COLLECT],
    );
  }

  @override
  String toString() {
    return name!;
  }

  ///this method will prevent the override of toString
  String userAsString() {
    return '#$id $name';
  }
}
