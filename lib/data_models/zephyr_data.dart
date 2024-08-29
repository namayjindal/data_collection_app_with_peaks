import 'dart:typed_data';

class ZephyrData {
  int field1;
  int field2;
  final double field3;
  final double field4;
  final double field5;
  final double field6;
  final double field7;
  final double field8;
  final int field9;

  ZephyrData({
    required this.field1,
    required this.field2,
    required this.field3,
    required this.field4,
    required this.field5,
    required this.field6,
    required this.field7,
    required this.field8,
    required this.field9,
  });

  static const int expectedLength = 4 + 4 + 4 * 6 + 1;

  factory ZephyrData.fromBytes(ByteData byteData) {
    if (byteData.lengthInBytes < expectedLength) {
      throw RangeError(
          "Invalid data length: Expected at least $expectedLength bytes but got ${byteData.lengthInBytes}");
    }

    int offset = 0;

    int field1 = byteData.getUint32(offset, Endian.little);
    offset += 4;

    int field2 = byteData.getUint32(offset, Endian.little);
    offset += 4;

    double field3 = byteData.getFloat32(offset, Endian.little);
    offset += 4;

    double field4 = byteData.getFloat32(offset, Endian.little);
    offset += 4;

    double field5 = byteData.getFloat32(offset, Endian.little);
    offset += 4;

    double field6 = byteData.getFloat32(offset, Endian.little);
    offset += 4;

    double field7 = byteData.getFloat32(offset, Endian.little);
    offset += 4;

    double field8 = byteData.getFloat32(offset, Endian.little);
    offset += 4;

    int field9 = byteData.getUint8(offset);

    return ZephyrData(
      field1: field1,
      field2: field2,
      field3: field3,
      field4: field4,
      field5: field5,
      field6: field6,
      field7: field7,
      field8: field8,
      field9: field9,
    );
  }

  List<dynamic> splitData() {
    List<dynamic> l = [];
    l.add(field1 / 1000);
    l.add(field2);
    l.add(field3.toStringAsFixed(4));
    l.add(field4.toStringAsFixed(4));
    l.add(field5.toStringAsFixed(4));
    l.add(field6.toStringAsFixed(4));
    l.add(field7.toStringAsFixed(4));
    l.add(field8.toStringAsFixed(4));
    l.add(field9);
    return l;
  }

  @override
  String toString() {
    var time = '${field1 / 1000}';
    return 'Timestamp: $time, Index: $field2, Acc_x: ${field3.toStringAsFixed(4)}, Acc_Y: ${field4.toStringAsFixed(4)}, Acc_Z: ${field5.toStringAsFixed(4)}, Gyro_X: ${field6.toStringAsFixed(4)}, Gyro_Y: ${field7.toStringAsFixed(4)}, Gyro_Z:${field8.toStringAsFixed(4)}, Battery: $field9';
  }
}
