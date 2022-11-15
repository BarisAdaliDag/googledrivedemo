// import 'dart:io';
// import 'dart:math';

// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:googleapis/drive/v3.dart' as ga;
// import 'package:http/http.dart' as http;
// import 'package:path/path.dart' as path;
// import 'package:http/io_client.dart';
// import 'package:path_provider/path_provider.dart';

// class GoogleHttpClient extends IOClient {
//   Map<String, String> _headers;

//   GoogleHttpClient(this._headers) : super();

//   @override
//   Future<IOStreamedResponse> send(http.BaseRequest request) =>
//       super.send(request..headers.addAll(_headers));

//   @override
//   Future<http.Response> head(Uri url, {Map<String, String>? headers}) =>
//       super.head(url, headers: headers!..addAll(_headers));
// }

// class MyHomePage extends StatefulWidget {
//   MyHomePage({required this.title});
//   final String title;
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   // late PermissionStatus _permissionStatus;
//   // @override
//   // void initState() {
//   //   super.initState();

//   //   () async {
//   //     _permissionStatus = await Permission.storage.status;

//   //     if (_permissionStatus != PermissionStatus.granted) {
//   //       PermissionStatus permissionStatus = await Permission.storage.request();
//   //       setState(() {
//   //         _permissionStatus = permissionStatus;
//   //       });
//   //     }
//   //   }();
//   // }

//   final storage = new FlutterSecureStorage();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn googleSignIn =
//       GoogleSignIn(scopes: ['https://www.googleapis.com/auth/drive.appdata']);
//   GoogleSignInAccount? googleSignInAccount;
//   ga.FileList? list;
//   var signedIn = false;

//   Future<void> _loginWithGoogle() async {
//     final googleSignIn =
//         GoogleSignIn.standard(scopes: [ga.DriveApi.driveScope]);
//     final GoogleSignInAccount? account = await googleSignIn.signIn();
//     print("User account $account");

//     final authHeaders = await account!.authHeaders;
//     final authenticateClient = GoogleAuthClient(authHeaders);
//     final driveApi = ga.DriveApi(authenticateClient);
// //----------
//     signedIn = await storage.read(key: "signedIn") == "true" ? true : false;
//     googleSignIn.onCurrentUserChanged
//         .listen((GoogleSignInAccount? googleSignInAccount) async {
//       if (googleSignInAccount != null) {
//         _afterGoogleLogin(googleSignInAccount);
//       }
//     });
//     if (signedIn) {
//       try {
//         googleSignIn.signInSilently().whenComplete(() => () {});
//       } catch (e) {
//         storage.write(key: "signedIn", value: "false").then((value) {
//           setState(() {
//             signedIn = false;
//           });
//         });
//       }
//     } else {
//       final GoogleSignInAccount? googleSignInAccount =
//           await googleSignIn.signIn();
//       _afterGoogleLogin(googleSignInAccount!);
//     }
//   }

//   Future<void> _afterGoogleLogin(GoogleSignInAccount gSA) async {
//     googleSignInAccount = gSA;
//     final GoogleSignInAuthentication googleSignInAuthentication =
//         await googleSignInAccount!.authentication;

//     final AuthCredential credential = GoogleAuthProvider.credential(
//       accessToken: googleSignInAuthentication.accessToken,
//       idToken: googleSignInAuthentication.idToken,
//     );

//     final UserCredential authResult =
//         await _auth.signInWithCredential(credential);
//     final User? user = authResult.user;

//     assert(!user!.isAnonymous);
//     assert(await user!.getIdToken() != null);

//     final User currentUser = _auth.currentUser!;
//     assert(user!.uid == currentUser.uid);

//     print('signInWithGoogle succeeded: $user');

//     storage.write(key: "signedIn", value: "true").then((value) {
//       setState(() {
//         signedIn = true;
//       });
//     });
//   }

//   void _logoutFromGoogle() async {
//     googleSignIn.signOut().then((value) {
//       print("User Sign Out");
//       storage.write(key: "signedIn", value: "false").then((value) {
//         setState(() {
//           signedIn = false;
//         });
//       });
//     });
//   }

//   Future<File> saveTemp(PlatformFile file, String name) async {
//     var directory = await getApplicationDocumentsDirectory();

//     File newFile = File('${directory.path}/${file.name}');
//     return File(file.path!).copy(newFile.path);
//   }

//   _uploadFileToGoogleDrive() async {
//     var client = GoogleHttpClient(await googleSignInAccount!.authHeaders);
//     var drive = ga.DriveApi(client);
//     ga.File fileToUpload = ga.File();
//     var fileTemp = await FilePicker.platform.pickFiles();
//     String basename = fileTemp!.files.first.name;
//     print('sss' + basename);
//     final fileTemp1 = fileTemp.files.first;
//     final file = await saveTemp(fileTemp1, basename);

//     fileToUpload.parents = ["appDataFolder"];

//     fileToUpload.name = path.basename(fileTemp.files.single.name);

//     print('----------');
//     print('file: ${file.openRead()}');
//     var response = await drive.files.create(
//       fileToUpload,
//       uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
//     );
//     print(response);
//     _listGoogleDriveFiles();
//   }
// //   _uploadFileToGoogleDrive() async {
// //     var client = GoogleHttpClient(await googleSignInAccount!.authHeaders);
// //     var drive = ga.DriveApi(client);
// //     ga.File fileToUpload = ga.File();
// //     var fileTemp = await FilePicker.platform.pickFiles();
// //     final fileTemp1 =fileTemp!.files.first;
// //     final file =await saveTemp(fileTemp1, fileTemp.files.single.name);
// //     fileToUpload.parents = ["appDataFolder"];

// //     //fileToUpload.name = path.basename(file!.files.single.name);
// //     print('----------');
// //     print(file.files.single.name);
// //     print(file.files.single.readStream);
// //     print(file.files.single.size);
// // // print('----------');
// // //     final Stream<List<int>> mediaStream =
// // //         Future.value([104, 105]).asStream().asBroadcastStream();

// // //     var media = ga.Media(mediaStream, 2);
// // //     var driveFile = ga.File();
// // //     driveFile.name = "hello_world.txt";
// // //     final result = await drive.files.create(driveFile, uploadMedia: media);
// //     print('----------');
// //     var response = await drive.files.create(
// //       fileToUpload,
// //       uploadMedia:
// //           ga.Media(file.files.single.readStream!, file.files.single.size),
// //     );
// //     print(response);
// //     _listGoogleDriveFiles();
// //   }

//   Future<void> _listGoogleDriveFiles() async {
//     var client = GoogleHttpClient(await googleSignInAccount!.authHeaders);
//     var drive = ga.DriveApi(client);
//     drive.files.list(spaces: 'appDataFolder').then((value) {
//       setState(() {
//         list = value;
//       });
//       for (var i = 0; i < list!.files!.length; i++) {
//         print("Id: ${list!.files![i].id} File Name:${list!.files![i].name}");
//       }
//     });
//   }

//   Future<void> _downloadGoogleDriveFile(String fName, String gdID) async {
//     var client = GoogleHttpClient(await googleSignInAccount!.authHeaders);
//     var drive = ga.DriveApi(client);
//     ga.Media? file = (await drive.files
//         .get(gdID, downloadOptions: ga.DownloadOptions.fullMedia)) as ga.Media?;
//     print(file!.stream);

//     final directory = await getExternalStorageDirectory();
//     print(directory!.path);
//     final saveFile = File(
//         '${directory.path}/${new DateTime.now().millisecondsSinceEpoch}$fName');
//     List<int> dataStore = [];
//     file.stream.listen((data) {
//       print("DataReceived: ${data.length}");
//       dataStore.insertAll(dataStore.length, data);
//     }, onDone: () {
//       print("Task Done");
//       saveFile.writeAsBytes(dataStore);
//       print("File saved at ${saveFile.path}");
//     }, onError: (error) {
//       print("Some Error");
//     });
//     setState(() {});
//     await Future.delayed(const Duration(seconds: 3), () {
//       showDialog(
//           context: context,
//           builder: (BuildContext context) => AlertDialog(
//                 title: Text(
//                   'resim',
//                 ),
//                 content: Image.file(File(saveFile.path)),
//                 actions: <Widget>[],
//               ));
//     });
//     setState(() {});
//   }

//   List<Widget> generateFilesWidget() {
//     List<Widget> listItem = <Widget>[];
//     if (list != null) {
//       for (var i = 0; i < list!.files!.length; i++) {
//         listItem.add(Row(
//           children: <Widget>[
//             Container(
//               width: MediaQuery.of(context).size.width * 0.05,
//               child: Text('${i + 1}'),
//             ),
//             Expanded(
//               child: Text(list?.files![i].name ?? ''),
//             ),
//             Container(
//               width: MediaQuery.of(context).size.width * 0.3,
//               child: FlatButton(
//                 child: Text(
//                   'Download',
//                   style: TextStyle(
//                     color: Colors.white,
//                   ),
//                 ),
//                 color: Colors.indigo,
//                 onPressed: () {
//                   _downloadGoogleDriveFile(
//                       list!.files![i].name ?? '', list!.files![i].id ?? '');
//                 },
//               ),
//             ),
//           ],
//         ));
//       }
//     }
//     return listItem;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             (signedIn
//                 ? FlatButton(
//                     child: Text('Upload File to Google Drive'),
//                     onPressed: _uploadFileToGoogleDrive,
//                     color: Colors.green,
//                   )
//                 : Container()),
//             (signedIn
//                 ? FlatButton(
//                     child: Text('List Google Drive Files'),
//                     onPressed: _listGoogleDriveFiles,
//                     color: Colors.green,
//                   )
//                 : Container()),
//             (signedIn
//                 ? Expanded(
//                     flex: 10,
//                     child: SingleChildScrollView(
//                       child: Column(
//                         children: generateFilesWidget(),
//                       ),
//                     ),
//                   )
//                 : Container()),
//             (signedIn
//                 ? FlatButton(
//                     child: Text('Google Logout'),
//                     onPressed: _logoutFromGoogle,
//                     color: Colors.green,
//                   )
//                 : FlatButton(
//                     child: Text('Google Login'),
//                     onPressed: _loginWithGoogle,
//                     color: Colors.red,
//                   )),
//           ],
//         ),
//       ),
//     );
//   }
// }
