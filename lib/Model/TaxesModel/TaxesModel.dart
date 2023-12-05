import '../../Helper/String.dart';

class TaxesModel {
  String? id, title, percentage, status;

  TaxesModel({
    this.id,
    this.title,
    this.percentage,
    this.status,
  });

  factory TaxesModel.fromJson(Map<String, dynamic> json) {
    return TaxesModel(
      id: json[ID],
      title: json['title'],
      percentage: json['percentage'],
      status: json[STATUS],
    );
  }

  @override
  String toString() {
    return title!;
  }

  ///this method will prevent the override of toString
  String userAsString() {
    return '#$id $title';
  }
}
