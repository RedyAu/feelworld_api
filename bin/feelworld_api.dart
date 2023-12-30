import 'dart:io';
import 'dart:convert';

void main(List<String> arguments) async {
  InternetAddress targetAddress = InternetAddress('192.168.1.100');
  int targetPort = 1000;
  //String message = FMessage(0, FCommand.connect.c, '66', '01', '0', '0').m; //'<T00006866010000CF>';
  /*String message = FMessage(
          0, FCommand.video.c, FCommand.video.sub['source']!, '00', '00', '00',
          read: true)
      .m; //'<T00006866010000CF>';*/

  RawDatagramSocket socket =
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5555);

  socket.listen((RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      Datagram? dg = socket.receive();
      print(
          '${dg?.address.address}:${dg?.port}\t${ascii.decode(dg?.data ?? [], allowInvalid: true)}\n${dg?.data.map((e) => e.toRadixString(2).padLeft(8, '0')).join(' ')}');
    }
  }, onError: (e) {
    print('Error: $e');
  }, onDone: () {
    print('Done.');
  }, cancelOnError: true);

  send(cmd) {
    socket.send(ascii.encode(cmd.m), targetAddress, targetPort);
    print('\nsend ----------> \t${cmd.m}');
  }

  scan() async {
    print('\n\n#########################################\n');
    // unknown message, maybe input formats?
    send(FMessage(1, 'F1', '03', '00', '00', '00'));
    await Future.delayed(Duration(milliseconds: 250));
    // switcher status (report in second response)
    send(FMessage(0, 'F1', '40', '01', '00', '00'));
  }

  stdin.listen((event) {
    scan();
  });
  scan();
}

class FMessage {
  bool transmit = true;
  bool read;
  int address = 0;
  int sequenceNumber;
  late int command;
  late int dat1;
  late int dat2;
  late int dat3;
  late int dat4;

  FMessage(this.sequenceNumber, String command, String dat1, String dat2,
      String dat3, String dat4,
      {this.read = false}) {
    this.command = int.parse(command, radix: 16);
    this.dat1 = int.parse(dat1, radix: 16);
    this.dat2 = int.parse(dat2, radix: 16);
    this.dat3 = int.parse(dat3, radix: 16);
    this.dat4 = int.parse(dat4, radix: 16);
  }
  String p(int i) {
    String s = (i & 0xff).toRadixString(16);
    if (s.length == 1) {
      return '0$s';
    }
    return s;
  }

  int get sum => address + sequenceNumber + command + dat1 + dat2 + dat3 + dat4;

  String get m {
    if (read) {
      dat1 |= 1;
    }

    return '<${transmit ? 'T' : 'F'}${p(address)}${p(sequenceNumber)}${p(command)}${p(dat1)}${p(dat2)}${p(dat3)}${p(dat4)}${p(sum)}>';
  }
}

enum FCommand {
  connect('68', {
    'connect': '66',
  }),
  video('75', {
    'source': '02',
    'pip': '1E',
  }),
  switching('78', {'tbar': '12', 'transition': '06'});

  const FCommand(this.c, this.sub);
  final String c;
  final Map<String, String> sub;
}
