import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Viewmodel/file_upload.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyC_ArhQ5whKxxwblogFJbY-_r-a7kxUZKQ',
        appId: 'filesupload-e4e90',
        messagingSenderId: '906307220736',
        projectId: 'filesupload-e4e90',
        storageBucket: 'myapp-b9yt18.appspot.com',
      )
  );
    runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      title: "Upload files to Firebase",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FileUploadScreen() ,
    );
  }
}

