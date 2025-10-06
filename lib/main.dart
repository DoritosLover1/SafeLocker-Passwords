// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/pointycastle.dart' as pc;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

Uint8List randomBytesGenerater(int length) {
  final rnd = Random.secure();
  return Uint8List.fromList(List<int>.generate(length, (_) => rnd.nextInt(256)));
}

Uint8List deriveKeyGenerater(String password, Uint8List salt,
    {int iterations = 100000, int keyLength = 32}) {
  final derivator = pc.KeyDerivator('SHA-256/HMAC/PBKDF2'); 
  final params = pc.Pbkdf2Parameters(salt, iterations, keyLength);
  derivator.init(params);
  return derivator.process(Uint8List.fromList(utf8.encode(password)));
}

class FileHelper {
  Future<String> get _appDirectoryLocation async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> getFile(String filename) async {
    final path = await _appDirectoryLocation;
    return File('$path/$filename.txt');
  }

  Future<File> writeToFileEncrypted(String filename, String content, String password, Uint8List salt) async {
    final file = await getFile(filename);
    
    final key = encrypt.Key(deriveKeyGenerater(password, salt));

    final ivBytes = randomBytesGenerater(12);
    final iv = encrypt.IV(ivBytes);
    final encrypted = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm)).encrypt(content, iv: iv);

    final combinedIvEncrypted = Uint8List.fromList(ivBytes + encrypted.bytes);
    return file.writeAsString(base64Encode(combinedIvEncrypted));
  }

  Future<String> readFromFileEncyrpted(String filename, String password, Uint8List salt) async {
    try {
      final file = await getFile(filename);
      final combined = base64Decode(await file.readAsString());

      final ivBytes = combined.sublist(0, 12);
      final encryptedBytes = combined.sublist(12);

      final key = encrypt.Key(deriveKeyGenerater(password, salt));

      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final iv = encrypt.IV(ivBytes);

      final decrypted = encrypter.decrypt(encrypt.Encrypted(Uint8List.fromList(encryptedBytes)), iv: iv);
      return decrypted;
    } catch (e) {
      return '';
    }
  }

  Future<List<FileSystemEntity>> listFiles() async {
    final path = await _appDirectoryLocation;
    final directory = Directory(path);
    final files = directory.listSync();
    return files.where((f) => f.path.endsWith(".txt")).toList();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Password Holder App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Secure It'),
    );
  }
}

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const MyAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final bigText = screenHeight * 0.05;
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: bigText,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  List<Map<String, String>> passwords = [];

void _addPasswordDialog(final screenHeight, final screenWidth, final boxSized){
  final TextEditingController filenameAreaController = TextEditingController();
  final TextEditingController contentAreaController = TextEditingController();
  final TextEditingController passwordAreaController = TextEditingController();
  final TextEditingController saltAreaController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(screenHeight * 0.03)),
          ),
          padding: EdgeInsets.all(screenHeight * 0.03),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add New Password',
                  style: TextStyle(fontSize: screenHeight * 0.04, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: boxSized),
                TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                    FilteringTextInputFormatter.deny(RegExp(r'\s$')),
                  ],
                  keyboardType: TextInputType.text,
                  controller: filenameAreaController,
                  decoration: const InputDecoration(
                    labelText: 'Filename',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder)
                  ),
                ),
                SizedBox(height: boxSized / 3),
                SingleChildScrollView(
                  child: TextField(
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                      FilteringTextInputFormatter.deny(RegExp(r'\s$')),
                    ],
                    controller: contentAreaController,
                    minLines: 3,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Padding(
                        padding:  EdgeInsetsGeometry.directional(bottom: screenHeight * 0.08),
                        child: Icon(Icons.description),
                      ),
                    labelText: 'Content',
                    alignLabelWithHint: true,
                  ),
                ),
                ),
                SizedBox(height: boxSized / 3),
                TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                    FilteringTextInputFormatter.deny(RegExp(r'\s$')),
                  ],
                  keyboardType: TextInputType.visiblePassword,
                  controller: passwordAreaController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                    labelText: 'Password',
                  ),
                  obscureText: true,
                ),
                SizedBox(height: boxSized / 3),
                TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                    FilteringTextInputFormatter.deny(RegExp(r'\s$')),
                  ],
                  controller: saltAreaController,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.security),
                    labelText: 'Salt',
                  ),
                ),
                SizedBox(height: boxSized),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      }, 
                      child: const Text('Cancel')
                    ),
                    SizedBox(width: boxSized / 3),
                    ElevatedButton(
                      onPressed: () async {
                        if(passwordAreaController.text.isEmpty || saltAreaController.text.isEmpty || filenameAreaController.text.isEmpty || contentAreaController.text.isEmpty){
                          showDialog(
                            context: context, 
                            builder: (BuildContext context) => (
                              AlertDialog(
                                title: const Text('Unable to proceed'),
                                content: Text('All fields are required.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    }, 
                                  child: const Text('Okey', style: TextStyle(color: Colors.redAccent),)
                                  ),
                                ],
                              )
                            ),
                          );
                          return;
                        }
                        final fileHelper = FileHelper();
                        await fileHelper.writeToFileEncrypted(
                          filenameAreaController.text,
                          contentAreaController.text,
                          passwordAreaController.text,
                          Uint8List.fromList(utf8.encode(saltAreaController.text)),
                        );
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        setState(() {});
                      }, 
                      child: const Text('Add')
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }

void _addRewritePasswordDialog(final screenHeight, final screenWidth, final boxSized, final existingFilename, final existingContent){
  final TextEditingController filenameAreaController = TextEditingController();
  final TextEditingController contentAreaController = TextEditingController();
  final TextEditingController passwordAreaController = TextEditingController();
  final TextEditingController saltAreaController = TextEditingController();

  filenameAreaController.text = existingFilename;
  contentAreaController.text = existingContent;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(screenHeight * 0.02)),
          ),
          padding: EdgeInsets.all(screenHeight * 0.03),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Content',
                  style: TextStyle(fontSize: screenHeight * 0.02, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: boxSized),
                TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                    FilteringTextInputFormatter.deny(RegExp(r'\s$')),
                  ],
                  keyboardType: TextInputType.text,
                  controller: filenameAreaController,
                  decoration: const InputDecoration(
                    labelText: 'Filename',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder)
                  ),
                ),
                SizedBox(height: boxSized / 3),
                SingleChildScrollView(
                  child: 
                  TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                    FilteringTextInputFormatter.deny(RegExp(r'\s$')),
                  ],
                    controller: contentAreaController,
                    minLines: 3,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Padding(
                        padding:  EdgeInsetsGeometry.directional(bottom: screenHeight * 0.08),
                        child: Icon(Icons.description),
                        ),
                      labelText: 'Content',
                      alignLabelWithHint: true,
                    ),
                  ),  
                ),
                SizedBox(height: boxSized / 3),
                TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                    FilteringTextInputFormatter.deny(RegExp(r'\s$')),
                  ],
                  keyboardType: TextInputType.visiblePassword,
                  controller: passwordAreaController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                    labelText: 'Password',
                  ),
                  obscureText: true,
                ),
                SizedBox(height: boxSized / 3),
                TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                    FilteringTextInputFormatter.deny(RegExp(r'\s$')),
                  ],
                  controller: saltAreaController,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.security),
                    labelText: 'Salt',
                  ),
                ),
                SizedBox(height: boxSized),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      }, 
                      child: const Text('Cancel')
                    ),
                    SizedBox(width: boxSized / 3),
                    ElevatedButton(
                      onPressed: () async {
                        if(passwordAreaController.text.isEmpty || saltAreaController.text.isEmpty || filenameAreaController.text.isEmpty || contentAreaController.text.isEmpty){
                          showDialog(
                            context: context, 
                            builder: (BuildContext context) => (
                              AlertDialog(
                                title: const Text('Unable to proceed'),
                                content: Text('All fields are required.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    }, 
                                  child: const Text('Okey', style: TextStyle(color: Colors.redAccent),)
                                  ),
                                ],
                              )
                            ),
                          );
                          return;
                        }
                        final fileHelper = FileHelper();
                        await fileHelper.writeToFileEncrypted(
                          filenameAreaController.text,
                          contentAreaController.text,
                          passwordAreaController.text,
                          Uint8List.fromList(utf8.encode(saltAreaController.text)),
                        );
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        setState(() {});
                      }, 
                      child: const Text('Add')
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final boxSized = screenWidth * 0.05;
    final bigText = screenHeight * 0.03;
    
    return Scaffold(
      appBar: MyAppBar(title: widget.title),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: FileHelper().listFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: screenHeight * 0.2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: boxSized),
                  Text(
                    'Password Holder',
                      style: TextStyle(fontSize: bigText, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: boxSized / 2),
                  const Text('Your passwords will be stored securely here'),
                ],
              ),
            );
          }

          final files = snapshot.data!;

          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final filename = file.uri.pathSegments.last;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: screenHeight * 0.02, vertical: screenHeight * 0.015),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(boxSized * 0.8),
                ),
                elevation: 3,
                child:
                  ListTile(
                    onTap: () async {
                      final screenHeight = MediaQuery.of(context).size.height;
                      final TextEditingController passwordAreaController = TextEditingController();
                      final TextEditingController saltAreaController = TextEditingController();
                      showModalBottomSheet(
                        context: context, 
                        builder: (BuildContext context) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(screenHeight * 0.02)),
                              ),
                              padding: EdgeInsets.all(screenHeight * 0.02),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Enter Password and Salt',
                                      style: TextStyle(fontSize: screenHeight * 0.03, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: boxSized),
                                    TextField(
                                      inputFormatters: [
                                        FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                                        FilteringTextInputFormatter.deny(RegExp(r'\s$')),
                                      ],
                                      keyboardType: TextInputType.visiblePassword,
                                      controller: passwordAreaController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.key),
                                        labelText: 'Password',
                                      ),
                                      obscureText: true,
                                    ),
                                    SizedBox(height: boxSized / 3),
                                    TextField(
                                      inputFormatters: [
                                        FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                                        FilteringTextInputFormatter.deny(RegExp(r'\s$')),
                                      ],
                                      controller: saltAreaController,
                                      keyboardType: TextInputType.visiblePassword,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.security),
                                        labelText: 'Salt',
                                      ),
                                    ),
                                    SizedBox(height: boxSized),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          }, 
                                          child: const Text('Cancel')
                                        ),
                                        SizedBox(width: boxSized / 3),
                                        ElevatedButton(
                                          onPressed: () async {
                                            if(passwordAreaController.text.isEmpty || saltAreaController.text.isEmpty){
                                                showDialog(
                                                  context: context, 
                                                  builder: (BuildContext context) =>(
                                                    AlertDialog(
                                                      title: const Text('Unable to proceed'),
                                                      content: Text('All fields are required.'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                          }, 
                                                          child: const Text('Okey', style: TextStyle(color: Colors.redAccent),
                                                        ),
                                                        ),
                                                      ],
                                                    )
                                                  )
                                                );
                                                return;
                                              }
                                            Navigator.of(context).pop();
                                            final content = await FileHelper().readFromFileEncyrpted(
                                              filename.replaceAll(".txt", ""),
                                              passwordAreaController.text,
                                              Uint8List.fromList(utf8.encode(saltAreaController.text))
                                            );
                                            if (!mounted) return;
                                            if(content.isNotEmpty){
                                              TextEditingController controllerContent = TextEditingController();
                                              controllerContent.text = content;
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: Text(filename),
                                                  content: SingleChildScrollView(
                                                    child: TextField(
                                                      controller: controllerContent,
                                                      readOnly: true,
                                                      maxLines: null,
                                                      decoration: const InputDecoration(
                                                        border: OutlineInputBorder(),
                                                      ),
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(this.context).pop(),
                                                      child: const Text("Close"),
                                                    ) 
                                                  ],
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Error: Unable to decrypt file. Check your password and salt.')),
                                              );
                                            }
                                          }, 
                                          child: const Text('Submit')
                                          
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      );
                    },
                    trailing: Wrap(
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent,),
                          onPressed: () async {
                            try {
                              showDialog(
                                context: context, 
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Deletion'),
                                    content: Text('Are you sure you want to delete $filename?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          file.delete();
                                          if (!mounted) return;
                                          Navigator.of(context).pop();
                                          setState(() {});
                                        }, 
                                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent),)
                                      ),
                                    ],
                                  );
                                }
                              );
                              if (!mounted) return;
                              setState(() {});
                            }   catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error deleting file')),
                              );
                            }
                          } 
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blueAccent,),
                          onPressed: () {
                            // Edit functionality can be implemented here
                          final screenHeight = MediaQuery.of(context).size.height;
                          final screenWidth = MediaQuery.of(context).size.width;
                          final TextEditingController passwordAreaController = TextEditingController();
                          final TextEditingController saltAreaController = TextEditingController();
                          showModalBottomSheet(
                            context: context, 
                            builder: (BuildContext context) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                padding: EdgeInsets.all(screenHeight * 0.02),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Enter Password and Salt',
                                        style: TextStyle(fontSize: screenHeight * 0.03, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: boxSized),
                                      TextField(
                                        inputFormatters: [
                                          FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                                          FilteringTextInputFormatter.deny(RegExp(r'\s$')),
                                        ],
                                        keyboardType: TextInputType.visiblePassword,
                                        controller: passwordAreaController,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.key),
                                          labelText: 'Password',
                                        ),
                                        obscureText: true,
                                      ),
                                      SizedBox(height: boxSized / 3),
                                      TextField(
                                        inputFormatters: [
                                          FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                                          FilteringTextInputFormatter.deny(RegExp(r'\s$')),
                                        ],
                                        controller: saltAreaController,
                                        keyboardType: TextInputType.visiblePassword,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.security),
                                          labelText: 'Salt',
                                        ),
                                      ),
                                      SizedBox(height: boxSized),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            }, 
                                            child: const Text('Cancel')
                                          ),
                                          SizedBox(width: boxSized / 3),
                                          ElevatedButton(
                                            onPressed: () async {
                                              if(passwordAreaController.text.isEmpty || saltAreaController.text.isEmpty){
                                                showDialog(
                                                  context: context, 
                                                  builder: (BuildContext context) =>(
                                                    AlertDialog(
                                                      title: const Text('Unable to proceed'),
                                                      content: Text('All fields are required.'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                          }, 
                                                          child: const Text('Okey', style: TextStyle(color: Colors.redAccent),
                                                        ),
                                                        ),
                                                      ],
                                                    )
                                                  )
                                                );
                                                return;
                                              }
                                              Navigator.of(context).pop();
                                              final content = await FileHelper().readFromFileEncyrpted(
                                                filename.replaceAll(".txt", ""),
                                                passwordAreaController.text,
                                                Uint8List.fromList(utf8.encode(saltAreaController.text))
                                              );
                                              if (!mounted) return;
                                              if(content.isNotEmpty){
                                                 _addRewritePasswordDialog(screenHeight, screenWidth, boxSized, filename.replaceAll(".txt", ""), content);
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Error: Unable to decrypt file. Check your password and salt.')),
                                                  );
                                                }
                                              }, 
                                                child: const Text('Submit')
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            );
                          },
                        ),
                      ],
                    ), 
                    leading: const Icon(Icons.description),
                    title: Text(filename),
                  ),
                );
              },
            );
          },
        ),
 
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addPasswordDialog(screenHeight, screenWidth, boxSized);
        },
        tooltip: 'Add Password',
        child: const Icon(Icons.add),
      ),
    );
  }
}
