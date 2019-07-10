import 'package:flutter/material.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:firebase/firestore.dart' as fs;

final colorMap = {
  'blue': Colors.blue,
  'green': Colors.green,
  'yellow': Colors.yellow,
  'red': Colors.red
};

/// Manages the Firestore data streams
class FirebaseInstance {
  FirebaseInstance() {
    _initializeFirebase();
  }
  fb.App app;
  fs.Firestore store;

  final pretty = ValueNotifier<bool>(false);
  final blueNotifier = ValueNotifier<int>(0);
  final greenNotifier = ValueNotifier<int>(0);
  final redNotifier = ValueNotifier<int>(0);
  final yellowNotifier = ValueNotifier<int>(0);

  void _initializeFirebase() {
    // Hack to ensure two apps are not created at the same time
    final appName = DateTime.now().toString();
    app = fb.initializeApp(
      name: appName,
      apiKey: 'AIzaSyAG7wN-Zv4VgD6aSUP7N9xthvkZ6QKg3Rs',
      authDomain: 'oscon-voter.firebaseapp.com',
      databaseURL: 'https://oscon-voter.firebaseio.com',
      projectId: 'oscon-voter',
      storageBucket: '',
      messagingSenderId: '150136682850',
      // appId: '1:150136682850:web:d14f3a68ab2b79f0',
    );

    store = fb.firestore(app);

    // Set up settings listener
    final settingsCollection = store.collection('settings');
    settingsCollection.onSnapshot.listen((querySnapshot) {
      querySnapshot.docChanges().forEach((change) {
        if (['added', 'modified'].contains(change.type))
          _settingsChanged(change);
      });
    });

    // Set up colour changes
    final ref = store.collection('votes');
    ref.onSnapshot.listen((querySnapshot) {
      querySnapshot.docChanges().forEach((change) {
        if (['added', 'modified'].contains(change.type)) _colourVote(change);
      });
    });
  }

  _settingsChanged(fs.DocumentChange change) {
    if (change.doc.id == 'web_app_settings') {
      print('Purdy is ${change.doc.data()['purdy']}');
      pretty.value = change.doc.data()['purdy'];
    }
  }

  void _colourVote(fs.DocumentChange change) {
    final data = change.doc.data();
    final color = change.doc.id;
    final votes = data['votes'] as num;
    colourNotifier(color).value = votes;
  }

  ValueNotifier<int> colourNotifier(String colour) {
    switch (colour) {
      case 'yellow':
        return yellowNotifier;
      case 'green':
        return greenNotifier;
      case 'blue':
        return blueNotifier;
      default:
        return redNotifier;
    }
  }

  void castVote(String colour) {
    final ref = store.doc('votes/$colour');
    ref.get().then((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final count = data['votes'] as num;
        ref.set({'votes': count + 1});
      } else {
        print('Color doesnt exist');
      }
    });
  }
}
