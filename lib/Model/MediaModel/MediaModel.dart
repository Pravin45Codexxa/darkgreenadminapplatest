import '../../Helper/String.dart';

class MediaModel {
  String? id, name, image, extention, subDic, size, path;
  bool isSelected = false;
  MediaModel({
    this.id,
    this.name,
    this.image,
    this.extention,
    this.subDic,
    this.size,
    this.isSelected = false,
    this.path,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
        id: json[ID],
        name: json["name"],
        image: json["image"],
        extention: json['extension'],
        size: json['size'],
        subDic: json['sub_directory'],
        path: json["relative_path"],
        isSelected: false);
  }
}
