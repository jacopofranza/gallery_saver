import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gallery_saver/files.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class GallerySaver {
  static const String channelName = 'gallery_saver';
  static const String methodSaveImage = 'saveImage';
  static const String methodSaveVideo = 'saveVideo';

  static const String pleaseProvidePath = 'Please provide valid file path.';
  static const String fileIsNotVideo = 'File on path is not a video.';
  static const String fileIsNotImage = 'File on path is not an image.';
  static const MethodChannel _channel = const MethodChannel(channelName);

  ///saves video from provided temp path and optional album name in gallery
  static Future<bool?> saveVideo(
    String path, {
    String? albumName,
    bool toDcim = false,
    Map<String, String>? headers,
    String? fileName,
  }) async {
    assert(path.isNotEmpty, pleaseProvidePath);
    assert(isVideo(path), fileIsNotVideo);

    File? tempFile;
    if (!isLocalFilePath(path)) {
      tempFile = await _downloadFile(path, headers: headers, fileName: fileName);
      path = tempFile.path;
    }

    bool? result = await _channel.invokeMethod(
      methodSaveVideo,
      <String, dynamic>{'path': path, 'albumName': albumName, 'toDcim': toDcim},
    );
    if (tempFile != null) {
      tempFile.delete();
    }
    return result;
  }

  ///saves image from provided temp path and optional album name in gallery
  static Future<bool?> saveImage(
    String path, {
    String? albumName,
    bool toDcim = false,
    Map<String, String>? headers,
    String? fileName,
  }) async {
    assert(path.isNotEmpty, pleaseProvidePath);
    assert(isImage(path), fileIsNotImage);

    File? tempFile;
    if (!isLocalFilePath(path)) {
      tempFile = await _downloadFile(path, headers: headers, fileName: fileName);
      path = tempFile.path;
    }

    bool? result = await _channel.invokeMethod(
      methodSaveImage,
      <String, dynamic>{'path': path, 'albumName': albumName, 'toDcim': toDcim},
    );
    if (tempFile != null) {
      tempFile.delete();
    }

    return result;
  }

  static Future<File> _downloadFile(
    String url, {
    Map<String, String>? headers,
    String? fileName,
  }) async {
    http.Client _client = new http.Client();
    var req = await _client.get(Uri.parse(url), headers: headers);
    if (req.statusCode >= 400) {
      throw HttpException(req.statusCode.toString());
    }
    var bytes = req.bodyBytes;
    String dir = (await getTemporaryDirectory()).path;
    String name = _shortenFileName(url, fileName);

    File file = new File('$dir/$name');

    await file.writeAsBytes(bytes);
    log('Saving $name, ${await file.length() ~/ 1024} Kb', name: 'GallerySaver');

    return file;
  }

  static String _shortenFileName(String url, String? fileName) {
    String name = fileName ?? basename(url).split('?')[0];
    final len = name.length;

    if (len > 255) {
      name = name.substring(len - 255, len);
    }

    return name;
  }
}
