import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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
  FirebaseAuth mAuth = FirebaseAuth.instance;

  double _uploadProgress = 0.0;
  bool _uploading = false;
  String? _message;
  String type = '';
  String filename = '';
  String? uploadedimageurl;
  UploadTask? uploadTask;
  String? path;
  late Uint8List file;

  Future<void> _selectFile() async {
    FilePickerResult? result;
    _message = null;
    _uploading = false;
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4'],
        withData: true
      );
    if(result != null && result.files.isNotEmpty) {
      path = result.files.single.path;
      if (result.files.single.bytes != null) {
        file = result.files.single.bytes!;
      } else{
        print('resultant file is null');
      }
    }
    filename = p.basenameWithoutExtension(path!);
    type = p.extension(path!);
    if ((File(path!).lengthSync()) > 10 * 1024 * 1024) {
        setState(() {
          _message = 'File size exceeds 10MB limit.';
        });
        return;
      }
      setState(() {
      });
    }

  _uploadFile() async {
    setState(() {
      _uploading = true;
    });

    if(mAuth.currentUser == null)
      mAuth.signInAnonymously();

    _message = await saveData(file: file, name: filename, type: type);

    setState(() {
      _uploading = false;
    });
  }

  Future<String> saveData(
      {required String name, required String type, required Uint8List file}) async {
    String resp = "Some error occurred";
    try {
      uploadedimageurl = await uploadImageToStorage(name, file);
      await _firestore.add({
        'name': name,
        'type': type,
        'imagelink': uploadedimageurl,
      });
      resp = 'File uploaded successfully';
    } catch (err) {
      print('err: $err');
      resp = err.toString();
    }
    return resp;
  }

  Future<String> uploadImageToStorage(String filename, Uint8List file) async {
    final _storage = FirebaseStorage.instance.ref();
    final refDir = _storage.child('files');
    try {
      final reffile = refDir.child('$filename$type');
      if(kIsWeb){
        uploadTask= reffile.putData(await file);
      }else {
        uploadTask =
            reffile.putFile(File(path!));
      }
      TaskSnapshot snapshot =
          await uploadTask!.whenComplete(() => print('completed'));
      uploadedimageurl = await reffile.getDownloadURL();
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
            if (path != null) Text('file picked is $filename'),
            SizedBox(height: 20),
            if (path != null && !_uploading && _message != 'File size exceeds 10MB limit.')
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
    if (path!.toLowerCase().endsWith('.mp4')) {
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
