import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _image; // file from user
  File? _imageFile; // memory file
  String headerText = "";
  String footerText = "";
  final GlobalKey globalKey = new GlobalKey();
  Random random = Random();
  bool imageSelected = false;

//image from gallery
  Future getImage() async {
    var image;
    try {
      image = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (e) {
      if (e is PlatformException) {
        // Handle platform exceptions
        print(e);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('An error occurred: ${e.message}'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
    setState(() {
      if (image != null) {
        imageSelected = true;
        _image = File(image.path); // Set _image to the selected image
      } else {
        imageSelected = false;
        _image = null; // Set _image to null if no image is selected
      }
    });

    new Directory('storage/emulated/0/' + 'MemeGenerator')
        .create(recursive: true);
  }

  //image from camera
  Future pickImageFromCamera() async {
    var image;
    try {
      image = await ImagePicker().pickImage(source: ImageSource.camera);
    } catch (e) {
      if (e is PlatformException) {
        // Handle platform exceptions
        print(e);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('An error occurred: ${e.message}'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
    setState(() {
      if (image != null) {
        imageSelected = true;
        _image = File(image.path);
      } else {
        imageSelected = false;
        _image = null;
      }
    });

    new Directory('storage/emulated/0/' + 'MemeGenerator')
        .create(recursive: true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showImageSourceDialog();
        },
        child: Icon(Icons.add_a_photo_outlined),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: size.height * 0.05,
              ),
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/troll.png"))),
              ),
              SizedBox(
                height: size.height * 0.05,
              ),
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/appimage.png"))),
              ),
              RepaintBoundary(
                key: globalKey,
                child: Stack(
                  children: [
                    if (_image != null)
                      Container(
                        height: size.height * 0.4,
                        width: size.width, // Use full width
                        child: _image != null
                            ? Image.file(
                                _image!,
                                fit: BoxFit
                                    .cover, // Maintain aspect ratio and cover the container
                              )
                            : Center(
                                child: Text("No image selected"),
                              ),
                      ),
                    Container(
                      height: size.height * 0.35,
                      width: size.width *
                          0.9, // Set a fixed height for the container
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              headerText,
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 22),
                            ),
                            Spacer(),
                            Text(footerText,
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 25)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: size.height * 0.1,
              ),
              imageSelected
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          TextFormField(
                            onChanged: (value) {
                              setState(() {
                                headerText = value;
                              }); //make header text the textfields text
                            },
                            decoration:
                                InputDecoration(hintText: "Header Text Here"),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          TextFormField(
                            onChanged: (value) {
                              setState(() {
                                footerText = value;
                              }); //make footer text the textfields text
                            },
                            decoration:
                                InputDecoration(hintText: "Footer Text Here"),
                          ),
                          SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                  onPressed: () {
                                    _takeScreenshot();
                                  },
                                  child: Text("Save Meme"))),
                        ],
                      ),
                    )
                  : Container(
                      child: Center(
                        child: Text("Select an Image to create a meme"),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  _takeScreenshot() async {
    RenderRepaintBoundary boundary =
        globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    final directory = (await getApplicationDocumentsDirectory()).path;
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      Uint8List pngBytes = byteData.buffer.asUint8List();
      File imgFile = File('$directory/screenshot${random.nextInt(200)}.png');
      setState(() {
        _imageFile = imgFile;
      });
      _saveFile(_imageFile!);
      imgFile.writeAsBytes(pngBytes);
    } else {}
  }

  _saveFile(File file) async {
    await _askPermission();
    final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(await file.readAsBytes()));
  }

  Future<void> _askPermission() async {
    //  permission to access external storage (documents folder)
    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      String dir =
          "${(await getExternalStorageDirectory())!.absolute.path}/documents";
    } else {}
  }

  // Function to show the image source dialog
  Future<void> _showImageSourceDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    pickImageFromCamera();
                  },
                ),
                SizedBox(height: 20),
                GestureDetector(
                  child: Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    getImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
