// import 'package:flutter/material.dart';

// import 'package:googleapis/drive/v3.dart' as drive;
// import 'package:google_sign_in/google_sign_in.dart' as signIn;
// import 'package:googledrive/GoogleAuthClient.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(

//         primarySwatch: Colors.blue,

//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   MyHomePage({required this.title});

//   final String title;

//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   Future<void> _incrementCounter() async {
//     setState(() {
//       _counter++;
//     });

//     final googleSignIn =
//         signIn.GoogleSignIn.standard(scopes: [drive.DriveApi.driveScope]);
//     final signIn.GoogleSignInAccount? account = await googleSignIn.signIn();
//     print("User account $account");

//     final authHeaders = await account!.authHeaders;
//     final authenticateClient = GoogleAuthClient(authHeaders);
//     final driveApi = drive.DriveApi(authenticateClient);

//     final Stream<List<int>> mediaStream = Future.value([104, 105]).asStream();
//     var media = new drive.Media(mediaStream, 2);
//     var driveFile = new drive.File();
//     driveFile.name = "hello_world.txt";
//     final result = await driveApi.files.create(driveFile, uploadMedia: media);
//     print("Upload result: $result");
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Invoke "debug painting" (press "p" in the console, choose the
//           // "Toggle Debug Paint" action from the Flutter Inspector in Android
//           // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
//           // to see the wireframe for each widget.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headline4,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }

import 'dart:io';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:googledrive/dummy/googleDriveTest.dart';
import 'package:googledrive/login.dart';
import 'package:googledrive/show_dialog.dart';
import 'package:googledrive/splash_screen.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import 'constants/color_constants.dart';
//import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Drive',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      //  home: GoogleDriveTest(),
      home: SplashScreen(),
    );
  }
}

class GoogleHttpClient extends IOClient {
  Map<String, String> _headers;

  GoogleHttpClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(http.BaseRequest request) =>
      super.send(request..headers.addAll(_headers));

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) =>
      super.head(url, headers: headers!..addAll(_headers));
}

class MyHomePage extends StatefulWidget {
  MyHomePage({required this.title});
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final storage = new FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn =
      GoogleSignIn(scopes: ['https://www.googleapis.com/auth/drive.appdata']);
  GoogleSignInAccount? googleSignInAccount;
  ga.FileList? list;
  var signedIn = false;
  String folderName = "Flutter-sample-by-tf";
  final mimeType = "application/vnd.google-apps.folder";
  bool _isLoading = false;

  Future<void> _loginWithGoogle() async {
    final googleSignIn =
        GoogleSignIn.standard(scopes: [ga.DriveApi.driveScope]);
    final GoogleSignInAccount? account = await googleSignIn.signIn();
    print("User account $account");

//----------
    signedIn = await storage.read(key: "signedIn") == "true" ? true : false;
    googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? googleSignInAccount) async {
      if (googleSignInAccount != null) {
        _afterGoogleLogin(googleSignInAccount);
      }
    });
    if (signedIn) {
      try {
        googleSignIn.signInSilently().whenComplete(() => () {});
      } catch (e) {
        storage.write(key: "signedIn", value: "false").then((value) {
          setState(() {
            signedIn = false;
          });
        });
      }
    } else {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      _afterGoogleLogin(googleSignInAccount!);
    }
  }

  Future<void> _afterGoogleLogin(GoogleSignInAccount gSA) async {
    googleSignInAccount = gSA;
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount!.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential authResult =
        await _auth.signInWithCredential(credential);
    final User? user = authResult.user;

    assert(!user!.isAnonymous);
    assert(await user!.getIdToken() != null);

    final User currentUser = _auth.currentUser!;
    assert(user!.uid == currentUser.uid);

    print('signInWithGoogle succeeded: $user');

    storage.write(key: "signedIn", value: "true").then((value) {
      setState(() {
        signedIn = true;
      });
    });
  }

  void _logoutFromGoogle() async {
    googleSignIn.signOut().then((value) {
      print("User Sign Out");
      storage.write(key: "signedIn", value: "false").then((value) {
        setState(() {
          signedIn = false;
        });
      });
    });
  }

  Future<File> saveTemp(PlatformFile file, String name) async {
    var directory = await getApplicationDocumentsDirectory();

    File newFile = File('${directory.path}/${file.name}');
    return File(file.path!).copy(newFile.path);
  }

  _uploadFileToGoogleDrive() async {
    var client = GoogleHttpClient(await googleSignInAccount!.authHeaders);
    var drive = ga.DriveApi(client);
    ga.File fileToUpload = ga.File();
    var fileTemp = await FilePicker.platform.pickFiles();
    String basename = fileTemp!.files.first.name;
    print('sss' + basename);
    final fileTemp1 = fileTemp.files.first;
    final file = await saveTemp(fileTemp1, basename);

    fileToUpload.parents = ["appDataFolder"];

    fileToUpload.name = path.basename(fileTemp.files.single.name);
    //final timestamp = DateFormat("yyyy-MM-dd-hhmmss").format(DateTime.now());

    print('----------');
    print('file: ${file.openRead()}');
    var response = await drive.files.create(
      fileToUpload,
      uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
    );
    print(response);
    _listGoogleDriveFiles();
  }

  Future<String?> _getFolderId(ga.DriveApi driveApi) async {
    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName'",
        $fields: "files(id, name)",
      );
      final files = found.files;
      if (files == null) {
        await showMessage(context, "Sign-in first", "Error");
        return null;
      }

      if (files.isNotEmpty) {
        return files.first.id;
      }

      // Create a folder
      var folder = new ga.File();
      folder.name = folderName;
      folder.mimeType = mimeType;
      final folderCreation = await driveApi.files.create(folder);
      print("Folder ID: ${folderCreation.id}");

      return folderCreation.id;
    } catch (e) {
      print(e);
      // I/flutter ( 6132): DetailedApiRequestError(status: 403, message: The granted scopes do not give access to all of the requested spaces.)
      return null;
    }
  }

  Future<void> _uploadToNormal() async {
    try {
      var client = GoogleHttpClient(await googleSignInAccount!.authHeaders);
      var driveApi = ga.DriveApi(client);
      if (driveApi == null) {
        return;
      }
      // Not allow a user to do something else
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        transitionDuration: Duration(seconds: 2),
        barrierColor: Colors.black.withOpacity(0.5),
        pageBuilder: (context, animation, secondaryAnimation) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      final folderId = await _getFolderId(driveApi);
      if (folderId == null) {
        await showMessage(context, "Failure", "Error");
        return;
      }

      // Create data here instead of loading a file
      final contents = "Technical Feeder";
      final Stream<List<int>> mediaStream =
          Future.value(contents.codeUnits).asStream().asBroadcastStream();
      var media = new ga.Media(mediaStream, contents.length);

      // Set up File info
      var driveFile = new ga.File();
      final timestamp = DateFormat("yyyy-MM-dd-hhmmss").format(DateTime.now());
      driveFile.name = "technical-feeder-$timestamp.txt";
      driveFile.modifiedTime = DateTime.now().toUtc();
      driveFile.parents = [folderId];

      // Upload
      final response =
          await driveApi.files.create(driveFile, uploadMedia: media);
      print("response: $response");

      // simulate a slow process
      await Future.delayed(Duration(seconds: 2));
    } finally {
      // Remove a dialog
      Navigator.pop(context);
    }
  }

  _uploadFileNormal() async {
    var client = GoogleHttpClient(await googleSignInAccount!.authHeaders);
    var drive = ga.DriveApi(client);
    ga.File fileToUpload = ga.File();
    var fileTemp = await FilePicker.platform.pickFiles();
    String basename = fileTemp!.files.first.name;
    print('sss' + basename);
    final fileTemp1 = fileTemp.files.first;
    final file = await saveTemp(fileTemp1, basename);

    fileToUpload.parents = ["appDataFolder"];

    fileToUpload.name = path.basename(fileTemp.files.single.name);
    final timestamp = DateFormat("yyyy-MM-dd-hhmmss").format(DateTime.now());

    print('----------');
    print('file: ${file.openRead()}');
    var response = await drive.files.create(
      fileToUpload,
      uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
    );
    print(response);
    _listGoogleDriveFiles();
  }
//   _uploadFileToGoogleDrive() async {
//     var client = GoogleHttpClient(await googleSignInAccount!.authHeaders);
//     var drive = ga.DriveApi(client);
//     ga.File fileToUpload = ga.File();
//     var fileTemp = await FilePicker.platform.pickFiles();
//     final fileTemp1 =fileTemp!.files.first;
//     final file =await saveTemp(fileTemp1, fileTemp.files.single.name);
//     fileToUpload.parents = ["appDataFolder"];

//     //fileToUpload.name = path.basename(file!.files.single.name);
//     print('----------');
//     print(file.files.single.name);
//     print(file.files.single.readStream);
//     print(file.files.single.size);
// // print('----------');
// //     final Stream<List<int>> mediaStream =
// //         Future.value([104, 105]).asStream().asBroadcastStream();

// //     var media = ga.Media(mediaStream, 2);
// //     var driveFile = ga.File();
// //     driveFile.name = "hello_world.txt";
// //     final result = await drive.files.create(driveFile, uploadMedia: media);
//     print('----------');
//     var response = await drive.files.create(
//       fileToUpload,
//       uploadMedia:
//           ga.Media(file.files.single.readStream!, file.files.single.size),
//     );
//     print(response);
//     _listGoogleDriveFiles();
//   }

  Future<void> _listGoogleDriveFiles() async {
    setState(() {
      list = null;
    });
    var client = GoogleHttpClient(await googleSignInAccount!.authHeaders);
    var drive = ga.DriveApi(client);
    drive.files
        .list(
      q: "'1KtQabq5FQ1-iDG1MmvnafS4GAox5I6iU' in parents and trashed=false",
      $fields: "files(id, name)",
    )
        .then((value) {
      //spaces: 'appDataFolder'
      //q: "mimeType = '$mimeType' and name = '$folderName'"
      setState(() {
        list = value;
        _isLoading = true;
      });
      for (var i = 0; i < list!.files!.length; i++) {
        print("Id: ${list!.files![i].id} File Name:${list!.files![i].name}");
      }
    });
  }

  Widget? generateFilesWidget() {
    // List<Widget> listItem = <Widget>[];
    if (list != null) {
      return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: list!.files!.length,
          itemBuilder: (context, index) {
            String ext = list!.files![index].name!
                .split(".")[list!.files![index].name!.split(".").length - 1];
            String _title = list!.files![index].name!.split(".")[0];
            String imageText = "";

            switch (ext.toLowerCase()) {
              case "png":
                imageText = "image.png";
                break;
              case "jpg":
                imageText = "image.png";
                break;
              case "jpeg":
                imageText = "image.png";
                break;
              case "dwg":
                imageText = "dwg.png";
                break;
              case "pdf":
                imageText = "pdf.png";
                break;
              case "docx":
                imageText = "word.png";
                break;
              case "doc":
                imageText = "word.png";
                break;
              case "xlsx":
                imageText = "excel.png";
                break;
              case "xls":
                imageText = "excel.png";
                break;
              default:
                imageText = "others.png";
                break;
            }

            return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Card(
                  child: ListTile(
                    onTap: (() async {
                      _downloadGoogleDriveFile(list!.files![index].name ?? '',
                          list!.files![index].id ?? '');
                    }),
                    title: AutoSizeText(
                      list!.files![index].name ?? '',
                      maxLines: 1,
                    ),
                    leading: Image.asset(
                      'assets/icons/$imageText',
                      width: 36,
                    ),
                    //leading: Image.asset('assets/pdf_icon.png'),
                    trailing: Icon(
                      Icons.arrow_forward,
                      color: kcRedColor,
                    ),
                  ),
                ));
          });

      // for (var i = 0; i < list!.files!.length; i++) {

      //   listItem.add(Row(
      //     children: <Widget>[
      //       Container(
      //         width: MediaQuery.of(context).size.width * 0.05,
      //         child: Text('${i + 1}'),
      //       ),
      //       Expanded(
      //         child: Text(list?.files![i].name ?? ''),
      //       ),
      //       Container(
      //         width: MediaQuery.of(context).size.width * 0.3,
      //         child: FlatButton(
      //           child: Text(
      //             'Download',
      //             style: TextStyle(
      //               color: Colors.white,
      //             ),
      //           ),
      //           color: Colors.indigo,
      //           onPressed: () {
      //             _downloadGoogleDriveFile(
      //                 list!.files![i].name ?? '', list!.files![i].id ?? '');
      //           },
      //         ),
      //       ),
      //     ],
      //   ));
      // }
    } else {
      Container();
    }
  }

  Future<void> _downloadGoogleDriveFile(String fName, String gdID) async {
    var client = GoogleHttpClient(await googleSignInAccount!.authHeaders);
    var drive = ga.DriveApi(client);
    ga.Media? file = (await drive.files
        .get(gdID, downloadOptions: ga.DownloadOptions.fullMedia)) as ga.Media?;
    print(file!.stream);

    final directory = await getExternalStorageDirectory();
    print(directory!.path);
    final saveFile = File(
        '${directory.path}/${new DateTime.now().millisecondsSinceEpoch}$fName');
    List<int> dataStore = [];
    file.stream.listen((data) {
      print("DataReceived: ${data.length}");
      dataStore.insertAll(dataStore.length, data);
    }, onDone: () {
      print("Task Done");
      saveFile.writeAsBytes(dataStore);
      print("File saved at ${saveFile.path}");
    }, onError: (error) {
      print("Some Error");
    });
    setState(() {});
    await Future.delayed(const Duration(seconds: 3), () {
      OpenFile.open(saveFile.path);
      // showDialog(
      //     context: context,
      //     builder: (BuildContext context) => AlertDialog(
      //           title: Text(
      //             'dosya',
      //           ),
      //           content: Image.file(File(saveFile.path)),
      //           actions: <Widget>[],
      //         ));
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            (signedIn
                ? FlatButton(
                    child: Text('Upload File to Google Drive'),
                    onPressed: _uploadFileToGoogleDrive,
                    color: Colors.green,
                  )
                : Container()),
            (signedIn
                ? FlatButton(
                    child: Text('gözükür olarak yükle '),
                    onPressed: _uploadToNormal,
                    color: Colors.green,
                  )
                : Container()),
            (signedIn
                ? FlatButton(
                    child: Text('List Google Drive Files'),
                    onPressed: _listGoogleDriveFiles,
                    color: Colors.green,
                  )
                : Container()),
            (signedIn
                ? _isLoading
                    ? Expanded(
                        flex: 10,
                        child: _listView(),
                      )
                    : Container()
                : Container()),
            FlatButton(
              child: Text('Google Logout'),
              onPressed: _logoutFromGoogle,
              color: Colors.green,
            ),
            FlatButton(
              child: Text('Google Login'),
              onPressed: _loginWithGoogle,
              color: Colors.red,
            )
          ],
        ),
      ),
    );
  }

  ListView _listView() {
    return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: list!.files!.length,
        itemBuilder: (context, index) {
          String ext = list!.files![index].name!
              .split(".")[list!.files![index].name!.split(".").length - 1];
          String _title = list!.files![index].name!.split(".")[0];
          String imageText = "";

          switch (ext.toLowerCase()) {
            case "png":
              imageText = "image.png";
              break;
            case "jpg":
              imageText = "image.png";
              break;
            case "jpeg":
              imageText = "image.png";
              break;
            case "dwg":
              imageText = "dwg.png";
              break;
            case "pdf":
              imageText = "pdf.png";
              break;
            case "docx":
              imageText = "word.png";
              break;
            case "doc":
              imageText = "word.png";
              break;
            case "xlsx":
              imageText = "excel.png";
              break;
            case "xls":
              imageText = "excel.png";
              break;
            default:
              imageText = "others.png";
              break;
          }
          // return Image(
          //   image: AssetImage("assets/icons/$imageText"),
          //   width: 55,
          // );

          return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Card(
                child: ListTile(
                  onTap: (() async {
                    _downloadGoogleDriveFile(list!.files![index].name ?? '',
                        list!.files![index].id ?? '');
                  }),
                  title: AutoSizeText(
                    list!.files![index].name ?? '',
                    maxLines: 1,
                  ),
                  leading: Image.asset(
                    'assets/icons/$imageText',
                    width: 36,
                  ),
                  //leading: Image.asset('assets/pdf_icon.png'),
                  trailing: Icon(
                    Icons.arrow_forward,
                    color: kcRedColor,
                  ),
                ),
              ));
        });
  }
}
