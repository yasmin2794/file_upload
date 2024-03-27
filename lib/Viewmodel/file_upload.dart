import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;

class FileUploadScreen extends StatefulWidget {
  @override
  _FileUploadScreenState createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {

  @override
  void initState(){
    super.initState();
  }

  CollectionReference _firestore = FirebaseFirestore.instance.collection('files');

  double _uploadProgress = 0.0;
  bool _uploading = false;
  String? _message;
  String type = '';
  String filename = '';
  String? uploadedimageurl;
  UploadTask? uploadTask;
  FilePickerResult? result;

  Future<void> _selectFile() async {
    _message = null;
    _uploading = false;
    result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4'],
    );
    final path = result?.files.single.path;
    filename = p.basenameWithoutExtension(path!);
    type = p.extension(path);
    if ((File(path).lengthSync()) > 10 * 1024 * 1024) {
        setState(() {
          _message = 'File size exceeds 10MB limit.';
        });
        return;
      }
      setState(() {
      });
    }

  Future<String> saveData(
      {required String name, required String type, required String file}) async {
    String resp = "Some error occurred";
    print('hi resp : $resp');
    try {
      uploadedimageurl = await uploadImageToStorage(name, file);
      print('uploadedimgurl: $uploadedimageurl');
      await _firestore.add({
        'name': name,
        'type': type,
        'imagelink': uploadedimageurl,
      });
      resp = 'File uploaded successfully';
      print('resp success: $resp');
    } catch (err) {
      print('err: $err');
      resp = err.toString();
    }
    return resp;
  }

  Future<String> uploadImageToStorage(String filename, String file) async {
    print('hi storage');
    final _storage = FirebaseStorage.instance.ref();
    final refDir = _storage.child('files');
    print('hi refdir ${refDir.name}');
    try {
      final reffile = refDir.child(filename);
      print('hi reffile: ${reffile.fullPath} ${reffile.name}');
      uploadTask = reffile.putFile(File(file));
      print('uploadtask: ${uploadTask.toString()}');
      TaskSnapshot snapshot =
          await uploadTask!.whenComplete(() => print('completed'));
      uploadedimageurl = await snapshot.ref.getDownloadURL();
      print('Download Link: $uploadedimageurl');
      setState(() {
        uploadTask = null;
      });

    }  catch (e) {
      print('e: $e');
      _message = e.toString();
    }
    return uploadedimageurl!;
  }

  _uploadFile() async {
    print('hi');
    if ((result?.files.single.path)!.isEmpty) {
      _message = 'Please select the file first';
      setState(() {
        print('returning');
      });
      return;
    }
    setState(() {
      _uploading = true;
    });
    print('_uploading : $_uploading');
    _message = await saveData(file: (result?.files.single.path)!, name: filename, type: type);

    setState(() {
      _uploading = false;
    });

    print('Uploading false: $_uploading');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Upload'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _selectFile,
              child: Text('Select File'),
            ),
            SizedBox(height: 10),
            if (((result?.files.single.path)) != null) Text('file picked is $filename'),
            SizedBox(height: 20),
            if (((result?.files.single.path)) != null && !_uploading && _message != 'File size exceeds 10MB limit.')
              ElevatedButton(
                onPressed: _uploadFile,
                child: Text('Upload File'),
              ),
            SizedBox(height: 10),
            if (_uploading) buildProgress(),
            SizedBox(height: 10),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 10),
            if (uploadedimageurl != null) _buildPreviewWidget(uploadedimageurl),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewWidget(String? uploadedimageurl) {
    if ((result?.files.single.path)!.toLowerCase().endsWith('.mp4')) {
      final controller = VideoPlayerController.file(File(uploadedimageurl!));
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: controller.value.isInitialized
            ? VideoPlayer(controller)
            : CircularProgressIndicator(),
      );
    } else {
      return Image.network(
        uploadedimageurl!,
        height: 400,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }

  Widget buildProgress() => StreamBuilder<TaskSnapshot>(
      stream: uploadTask?.snapshotEvents,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          _uploadProgress = data.bytesTransferred / data.totalBytes;
          return SizedBox(
            height: 50,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.grey,
                  color: Colors.green,
                ),
                Center(
                  child: Text(
                    '${(100 * _uploadProgress).roundToDouble()}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const SizedBox(
            height: 50,
          );
        }
      });
}
