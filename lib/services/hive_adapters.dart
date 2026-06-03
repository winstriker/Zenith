import 'package:hive/hive.dart';
import '../models/flight_point.dart';
import '../models/flight_session.dart';

class FlightPointAdapter extends TypeAdapter<FlightPoint> {
  @override
  final int typeId = 0;

  @override
  FlightPoint read(BinaryReader reader) {
    return FlightPoint(
      latitude: reader.readDouble(),
      longitude: reader.readDouble(),
      altitude: reader.readDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      speed: reader.readBool() ? reader.readDouble() : null,
      heading: reader.readBool() ? reader.readDouble() : null,
    );
  }

  @override
  void write(BinaryWriter writer, FlightPoint obj) {
    writer.writeDouble(obj.latitude);
    writer.writeDouble(obj.longitude);
    writer.writeDouble(obj.altitude);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeBool(obj.speed != null);
    if (obj.speed != null) writer.writeDouble(obj.speed!);
    writer.writeBool(obj.heading != null);
    if (obj.heading != null) writer.writeDouble(obj.heading!);
  }
}

class FlightSessionAdapter extends TypeAdapter<FlightSession> {
  @override
  final int typeId = 1;

  @override
  FlightSession read(BinaryReader reader) {
    return FlightSession(
      sessionId: reader.readString(),
      title: reader.readString(),
      aircraftType: reader.readBool() ? reader.readString() : null,
      departure: reader.readBool() ? reader.readString() : null,
      arrival: reader.readBool() ? reader.readString() : null,
      startTime: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      endTime: reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
      status: reader.readBool()
          ? FlightStatus.inProgress
          : FlightStatus.recorded,
      points: reader.readList().cast<FlightPoint>(),
    );
  }

  @override
  void write(BinaryWriter writer, FlightSession obj) {
    writer.writeString(obj.sessionId);
    writer.writeString(obj.title);
    writer.writeBool(obj.aircraftType != null);
    if (obj.aircraftType != null) writer.writeString(obj.aircraftType!);
    writer.writeBool(obj.departure != null);
    if (obj.departure != null) writer.writeString(obj.departure!);
    writer.writeBool(obj.arrival != null);
    if (obj.arrival != null) writer.writeString(obj.arrival!);
    writer.writeInt(obj.startTime.millisecondsSinceEpoch);
    writer.writeBool(obj.endTime != null);
    if (obj.endTime != null)
      writer.writeInt(obj.endTime!.millisecondsSinceEpoch);
    writer.writeBool(obj.status == FlightStatus.inProgress);
    writer.writeList(obj.points);
  }
}
