import 'dart:io';

import 'package:meta/meta.dart';

abstract class Exporter {
  /// writes to a new line by writting a leading \n
  /// and the writing [indent]  tabs.
  void write(String string,
      {@required int indent, @required int page, bool endOfLine = false});

  /// append to an existing line
  void append(String string, {@required int page, bool endOfLine = false});
}

class ExportedPages {
  var pages = <ExportedPage>[];

  void add(String file) {
    pages.add(ExportedPage(file));
  }

  void write(int page, String string) {
    pages[page].write(string);
  }
}

class ExportedPage {
  final String path;
  RandomAccessFile raf;

  ExportedPage(this.path) {
    var file = File(path);
    raf = file.openSync(mode: FileMode.write);
  }

  void write(String string) {
    raf.writeStringSync(string);
  }

  void close() {
    raf.closeSync();
  }
}
