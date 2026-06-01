import 'package:hive/hive.dart';
import '../models/flight_point.dart';
import '../models/flight_session.dart';
import '../models/airport.dart';
import '../models/country.dart';
import '../models/region.dart';

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
      endTime: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      status: reader.readBool() ? FlightStatus.inProgress : FlightStatus.recorded,
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
    if (obj.endTime != null) writer.writeInt(obj.endTime!.millisecondsSinceEpoch);
    writer.writeBool(obj.status == FlightStatus.inProgress);
    writer.writeList(obj.points);
  }
}

class AirportAdapter extends TypeAdapter<Airport> {
  @override
  final int typeId = 2;

  @override
  Airport read(BinaryReader reader) {
    return Airport(
      id: reader.readString(),
      ident: reader.readString(),
      type: reader.readString(),
      name: reader.readString(),
      latitudeDeg: reader.readBool() ? reader.readDouble() : null,
      longitudeDeg: reader.readBool() ? reader.readDouble() : null,
      elevationFt: reader.readBool() ? reader.readDouble() : null,
      continent: reader.readBool() ? reader.readString() : null,
      isoCountry: reader.readBool() ? reader.readString() : null,
      isoRegion: reader.readBool() ? reader.readString() : null,
      municipality: reader.readBool() ? reader.readString() : null,
      scheduledService: reader.readBool(),
      icaoCode: reader.readBool() ? reader.readString() : null,
      iataCode: reader.readBool() ? reader.readString() : null,
      gpsCode: reader.readBool() ? reader.readString() : null,
      localCode: reader.readBool() ? reader.readString() : null,
      homeLink: reader.readBool() ? reader.readString() : null,
      wikipediaLink: reader.readBool() ? reader.readString() : null,
      keywords: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, Airport obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.ident);
    writer.writeString(obj.type);
    writer.writeString(obj.name);
    writer.writeBool(obj.latitudeDeg != null);
    if (obj.latitudeDeg != null) writer.writeDouble(obj.latitudeDeg!);
    writer.writeBool(obj.longitudeDeg != null);
    if (obj.longitudeDeg != null) writer.writeDouble(obj.longitudeDeg!);
    writer.writeBool(obj.elevationFt != null);
    if (obj.elevationFt != null) writer.writeDouble(obj.elevationFt!);
    writer.writeBool(obj.continent != null);
    if (obj.continent != null) writer.writeString(obj.continent!);
    writer.writeBool(obj.isoCountry != null);
    if (obj.isoCountry != null) writer.writeString(obj.isoCountry!);
    writer.writeBool(obj.isoRegion != null);
    if (obj.isoRegion != null) writer.writeString(obj.isoRegion!);
    writer.writeBool(obj.municipality != null);
    if (obj.municipality != null) writer.writeString(obj.municipality!);
    writer.writeBool(obj.scheduledService);
    writer.writeBool(obj.icaoCode != null);
    if (obj.icaoCode != null) writer.writeString(obj.icaoCode!);
    writer.writeBool(obj.iataCode != null);
    if (obj.iataCode != null) writer.writeString(obj.iataCode!);
    writer.writeBool(obj.gpsCode != null);
    if (obj.gpsCode != null) writer.writeString(obj.gpsCode!);
    writer.writeBool(obj.localCode != null);
    if (obj.localCode != null) writer.writeString(obj.localCode!);
    writer.writeBool(obj.homeLink != null);
    if (obj.homeLink != null) writer.writeString(obj.homeLink!);
    writer.writeBool(obj.wikipediaLink != null);
    if (obj.wikipediaLink != null) writer.writeString(obj.wikipediaLink!);
    writer.writeBool(obj.keywords != null);
    if (obj.keywords != null) writer.writeString(obj.keywords!);
  }
}

class CountryAdapter extends TypeAdapter<Country> {
  @override
  final int typeId = 3;

  @override
  Country read(BinaryReader reader) {
    return Country(
      id: reader.readString(),
      code: reader.readString(),
      name: reader.readString(),
      continent: reader.readString(),
      wikipediaLink: reader.readBool() ? reader.readString() : null,
      keywords: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, Country obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.code);
    writer.writeString(obj.name);
    writer.writeString(obj.continent);
    writer.writeBool(obj.wikipediaLink != null);
    if (obj.wikipediaLink != null) writer.writeString(obj.wikipediaLink!);
    writer.writeBool(obj.keywords != null);
    if (obj.keywords != null) writer.writeString(obj.keywords!);
  }
}

class RegionAdapter extends TypeAdapter<Region> {
  @override
  final int typeId = 4;

  @override
  Region read(BinaryReader reader) {
    return Region(
      id: reader.readString(),
      code: reader.readString(),
      localCode: reader.readString(),
      name: reader.readString(),
      continent: reader.readString(),
      isoCountry: reader.readString(),
      wikipediaLink: reader.readBool() ? reader.readString() : null,
      keywords: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, Region obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.code);
    writer.writeString(obj.localCode);
    writer.writeString(obj.name);
    writer.writeString(obj.continent);
    writer.writeString(obj.isoCountry);
    writer.writeBool(obj.wikipediaLink != null);
    if (obj.wikipediaLink != null) writer.writeString(obj.wikipediaLink!);
    writer.writeBool(obj.keywords != null);
    if (obj.keywords != null) writer.writeString(obj.keywords!);
  }
}
