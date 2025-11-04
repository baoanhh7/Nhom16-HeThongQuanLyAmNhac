// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'downloadedsong.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class DownloadedSongAdapter extends TypeAdapter<DownloadedSong> {
//   @override
//   final int typeId = 0;

//   @override
//   DownloadedSong read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return DownloadedSong(
//       songId: fields[0] as int,
//       songName: fields[1] as String,
//       artistName: fields[2] as String,
//       localPath: fields[3] as String,
//       imagePath: fields[4] as String,
//       downloadDate: fields[5] as DateTime,
//       fileSize: fields[6] as int,
//       lrcPath: fields[7] as String?,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, DownloadedSong obj) {
//     writer
//       ..writeByte(8)
//       ..writeByte(0)
//       ..write(obj.songId)
//       ..writeByte(1)
//       ..write(obj.songName)
//       ..writeByte(2)
//       ..write(obj.artistName)
//       ..writeByte(3)
//       ..write(obj.localPath)
//       ..writeByte(4)
//       ..write(obj.imagePath)
//       ..writeByte(5)
//       ..write(obj.downloadDate)
//       ..writeByte(6)
//       ..write(obj.fileSize)
//       ..writeByte(7)
//       ..write(obj.lrcPath);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is DownloadedSongAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
