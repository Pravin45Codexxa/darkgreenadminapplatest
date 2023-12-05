import '../../../Helper/String.dart';

class AttributeModel {
  String? id, name, attributeSetId, attributeSetName, status;

  AttributeModel(
      {this.id,
      this.name,
      this.status,
      this.attributeSetId,
      this.attributeSetName});

  factory AttributeModel.fromJson(Map<String, dynamic> json) {
    return  AttributeModel(
      id: json[ID],
      name: json['name'],
      status: json["status"],
      attributeSetId: json["attribute_set_id"],
      attributeSetName: json["attribute_set_name"],
    );
  }
}
