// storage_queue.dart - Update uploadFile method
import 'dart:io';
// import 'dart:ui';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class StorageQueue {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Map<String, UploadTask> _uploads = {};
  final Map<String, bool> _cancelledUploads = {};

  Future<String> uploadFile({
    required File file,
    required String path,
    required String idempotencyKey,
    ValueChanged<double>?
        onProgress, // Changed from VoidCallback
  }) async {
    if (_uploads.containsKey(idempotencyKey)) {
      return await _getUploadResult(idempotencyKey);
    }

    final task =
        _uploadWithProgress(file, path, onProgress);
    _uploads[idempotencyKey] = task;

    try {
      final snapshot = await task;
      _cancelledUploads.remove(idempotencyKey);
      return await snapshot.ref.getDownloadURL();
    } finally {
      _uploads.remove(idempotencyKey);
    }
  }

  UploadTask _uploadWithProgress(File file, String path,
      ValueChanged<double>? onProgress) {
    final ref = _storage.ref(path);
    final task = ref.putFile(file);

    if (onProgress != null) {
      task.snapshotEvents.listen((snapshot) {
        final progress =
            snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    return task;
  }

  // Rest of the class remains the same...
  Future<String> _getUploadResult(
      String idempotencyKey) async {
    final task = _uploads[idempotencyKey];
    if (task == null) throw Exception('Upload not found');
    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  void cancelUpload(String idempotencyKey) {
    final task = _uploads[idempotencyKey];
    if (task != null) {
      task.cancel();
      _uploads.remove(idempotencyKey);
      _cancelledUploads[idempotencyKey] = true;
    }
  }

  void pauseUpload(String idempotencyKey) {
    final task = _uploads[idempotencyKey];
    task?.pause();
  }

  void resumeUpload(String idempotencyKey) {
    final task = _uploads[idempotencyKey];
    task?.resume();
  }

  bool isUploading(String idempotencyKey) =>
      _uploads.containsKey(idempotencyKey);
  bool isCancelled(String idempotencyKey) =>
      _cancelledUploads[idempotencyKey] == true;

  Future<void> deleteFile(String path) async {
    await _storage.ref(path).delete();
  }

  Future<String> getDownloadUrl(String path) async {
    return await _storage.ref(path).getDownloadURL();
  }
}
