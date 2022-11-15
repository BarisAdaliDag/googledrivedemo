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
import 'package:googledrive/services/secureStorage.dart';
import 'package:googledrive/show_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import 'constants/color_constants.dart';
import 'login.dart';

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

class HomeScreen extends StatefulWidget {
  final String? folderId;
  final String? title;

  const HomeScreen(
      {this.title = 'Google Drive',
      this.folderId = "mimeType = 'application/vnd.google-apps.folder'"});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = new FlutterSecureStorage();
  final storageSecure = SecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn =
      GoogleSignIn(scopes: ['https://www.googleapis.com/auth/drive.appdata']);
  GoogleSignInAccount? googleSignInAccount;
  ga.FileList? list;
  var signedIn = false;
  String folderName = "SZG_Bakim_Drive";
  final mimeType = "application/vnd.google-apps.folder";
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _afterGoogleLogin();
    _listGoogleDriveFiles(query: widget.folderId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),

        actions: [
          IconButton(onPressed: _logoutFromGoogle, icon: Icon(Icons.logout))
        ],
        // automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadToNormal,
        child: Icon(Icons.add),
      ),
      body: Center(
        child: !_isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  (signedIn
                      ? !_isLoading
                          ? Expanded(
                              flex: 10,
                              child: _listView(),
                            )
                          : Container()
                      : Container()),
                ],
              )
            : CircularProgressIndicator(),
      ),
    );
  }

  Future<void> _afterGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });
    googleSignInAccount = await googleSignIn.signIn();

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

  Future<Map<String, String>> get authHeadersx async {
    var credentials = await storageSecure.getCredentials();
    final String token = credentials!["accToken"];
    return <String, String>{
      "Authorization": "Bearer $token",
      "X-Goog-AuthUser": "0",
    };
  }

  ListView _listView() {
    return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: list!.files!.length,
        itemBuilder: (context, index) {
          String imageText = "";
          if (!list!.files![index].name!.contains('.')) {
            imageText = "folder.png";
          } else {
            String ext = list!.files![index].name!
                .split(".")[list!.files![index].name!.split(".").length - 1];
            String _title = list!.files![index].name!.split(".")[0];

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
                print('name' + list!.files![index].name!);
                print('name.' + ext);
                break;
            }
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
                    print(list!.files![index].name! + 'aas');
                    if (list!.files![index].name!.contains('.')) {
                      _downloadGoogleDriveFile(list!.files![index].name ?? '',
                          list!.files![index].id ?? '');
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HomeScreen(
                                  title: list!.files![index].name,
                                  folderId:
                                      "'${list!.files![index].id}' in parents and trashed=false")));
                      // _listGoogleDriveFiles(
                      //     query:
                      //         "'${list!.files![index].id}' in parents and trashed=false");
                    }
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

  void _logoutFromGoogle() async {
    await FirebaseAuth.instance.signOut().then((value) {
      print("User Sign Out");
      storage.write(key: "signedIn", value: "false").then((value) {
        setState(() {
          signedIn = false;
        });
      });
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          ModalRoute.withName("/Login"));
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
    //_listGoogleDriveFiles(query: "mimeType = '$mimeType'");
  }

  Future<String?> _getFolderId(ga.DriveApi driveApi,
      {String query =
          "mimeType = 'application/vnd.google-apps.folder' and name = 'SZG_Bakim_Drive'"}) async {
    try {
      final found = await driveApi.files.list(
        q: query,
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
      var client = GoogleHttpClient(await authHeadersx);
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

      final folderId = //widget.folderId;
          //todo
          await _getFolderId(
        driveApi,
      );
      if (folderId == null) {
        await showMessage(context, "Failure", "Error");
        return;
      }
//--
      // ga.File fileToUpload = ga.File();
      // var fileTemp = await FilePicker.platform.pickFiles();
      // String basename = fileTemp!.files.first.name;
      // print('sss' + basename);
      // final fileTemp1 = fileTemp.files.first;
      // final file = await saveTemp(fileTemp1, basename);

      // fileToUpload.parents = ["folderId"];
      // print('sasd');
      // print(fileToUpload.parents);

      // fileToUpload.name = path.basename(fileTemp.files.single.name);
      // //final timestamp = DateFormat("yyyy-MM-dd-hhmmss").format(DateTime.now());

      // print('----------');
      // print('file: ${file.openRead()}');
      // var response = await driveApi.files.create(
      //   fileToUpload,
      //   uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
      // );

//--
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

      // // simulate a slow process
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

    print('----------');
    print('file: ${file.openRead()}');
    var response = await drive.files.create(
      fileToUpload,
      uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
    );
    print(response);
    // _listGoogleDriveFiles();
  }

  Future<void> _listGoogleDriveFiles({required String query}) async {
    setState(() {
      list = null;
      _isLoading = true;
    });
    var client = GoogleHttpClient(await authHeadersx);
    print('client' + client.toString());
    var drive = ga.DriveApi(client);
    drive.files
        .list(
      q: query,
      $fields: "files(id, name)",
    )
        .then((value) {
      //spaces: 'appDataFolder'
      //q: "mimeType = '$mimeType' and name = '$folderName'"
      //q: "'1KtQabq5FQ1-iDG1MmvnafS4GAox5I6iU' in parents and trashed=false"
      setState(() {
        list = value;
        _isLoading = false;
      });
      for (var i = 0; i < list!.files!.length; i++) {
        print("Id: ${list!.files![i].id} File Name:${list!.files![i].name}");
      }
    });
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
    });
    setState(() {});
  }
}
