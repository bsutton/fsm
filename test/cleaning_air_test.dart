import 'package:dcli/dcli.dart' hide equals;
import 'package:fsm2/fsm2.dart';
import 'package:fsm2/src/types.dart';
import 'package:fsm2/src/virtual_root.dart';
import 'package:test/test.dart';

void main() async {
  test('fork', () async {
    var machine = createMachine();
    expect(machine.isInState<MonitorAir>(), equals(true));
    machine.applyEvent(OnBadAir());
    await machine.waitUntilQuiescent;
    expect(machine.isInState<HandleFan>(), equals(true));
    expect(machine.isInState<HandleLamp>(), equals(true));
    expect(machine.isInState<CleanAir>(), equals(true));
    expect(machine.isInState<MaintainAir>(), equals(true));

    var som = machine.stateOfMind;
    var paths = som.activeLeafStates();
    expect(paths.length, equals(3));
    var types = som.pathForLeafState(HandleFan).path.map((sd) => sd.stateType).toList();
    expect(types, equals([HandleFan, CleanAir, MaintainAir, VirtualRoot]));
    types = som.pathForLeafState(HandleLamp).path.map((sd) => sd.stateType).toList();
    expect(types, equals([HandleLamp, CleanAir, MaintainAir, VirtualRoot]));
    types = som.pathForLeafState(WaitForGoodAir).path.map((sd) => sd.stateType).toList();
    expect(types, equals([WaitForGoodAir, CleanAir, MaintainAir, VirtualRoot]));
    print('done1');
    print('done2');
  }, skip: false);

  test('export', () async {
    var machine = createMachine();
    machine.export('test/smcat/cleaning_air_test.smcat');
    var lines = read('test/smcat/cleaning_air_test.smcat').toList().reduce((value, line) => value += '\n' + line);

    expect(lines, equals(smcGraph));
  }, skip: false);
}

StateMachine createMachine() {
  StateMachine machine;

  // ignore: unused_local_variable
  var lightOn = false;
  // ignore: unused_local_variable
  var fanOn = false;

  machine = StateMachine.create((g) => g
    ..initialState<MaintainAir>()
    ..state<MaintainAir>((b) => b
      ..state<MonitorAir>((b) => b
        ..onFork<OnBadAir>((b) => b..target<HandleFan>()..target<HandleLamp>()..target<WaitForGoodAir>(),
            condition: (s, e) => e.quality < 10))
      ..coregion<CleanAir>((b) => b
        ..state<HandleFan>((b) => b
          ..onEnter((s, e) async => fanOn = true)
          ..onExit((s, e) async => fanOn = false)
          ..onJoin<OnFanRunning, MonitorAir>(condition: ((e) => e.speed > 5))
          ..state<FanOff>((b) => b..on<OnTurnFanOn, FanOn>(sideEffect: () async => lightOn = true))
          ..state<FanOn>((b) => b
            ..onEnter((s, e) async => machine.applyEvent(OnFanRunning()))
            ..on<OnTurnFanOff, FanOff>(sideEffect: () async => lightOn = false)))
        ..state<HandleLamp>((b) => b
          ..onEnter((s, e) async => lightOn = true)
          ..onExit((s, e) async => lightOn = false)
          ..onJoin<OnLampOn, MonitorAir>()
          ..state<LampOff>((b) => b..on<OnTurnLampOn, LampOn>(sideEffect: () async => lightOn = true))
          ..state<LampOn>((b) => b
            ..onEnter((s, e) async => machine.applyEvent(OnLampOn()))
            ..on<OnTurnLampOff, LampOff>(sideEffect: () async => lightOn = false)))
        ..state<WaitForGoodAir>((b) => b..onJoin<OnGoodAir, MonitorAir>())))
    ..onTransition((s, e, st) {}));

  return machine;
}

var smcGraph = '''

MaintainAir {
	MonitorAir {
		MonitorAir => ]MonitorAir.Fork : OnBadAir;
		]MonitorAir.Fork => HandleFan : ;
		]MonitorAir.Fork => HandleLamp : ;
		]MonitorAir.Fork => WaitForGoodAir : ;
	},
	CleanAir.parallel [label="CleanAir"] {
		HandleFan {
			FanOff {
				FanOff => FanOn : OnTurnFanOn;
			},
			FanOn {
				FanOn => FanOff : OnTurnFanOff;
			};
			FanOff.initial => FanOff;
		},
		HandleLamp {
			LampOff {
				LampOff => LampOn : OnTurnLampOn;
			},
			LampOn {
				LampOn => LampOff : OnTurnLampOff;
			};
			LampOff.initial => LampOff;
		},
		WaitForGoodAir;
		HandleFan => ]MonitorAir.Join : OnFanRunning;
		]MonitorAir.Join => MonitorAir : ;
		HandleLamp => ]MonitorAir.Join : OnLampOn;
		WaitForGoodAir => ]MonitorAir.Join : OnGoodAir;
	};
	MonitorAir.initial => MonitorAir;
};
initial => MaintainAir : MaintainAir;''';

var graph = '''stateDiagram-v2
    [*] --> MaintainAir
    state MaintainAir {
        [*] --> MonitorAir 
        
        CleanAir --> MonitorAir : onGoodAir 
        MonitorAir  --> CleanAir : OnBadAir

        state CleanAir {
        [*] --> HandleEquipment
        HandleEquipment --> [*]
        state HandleEquipment {
            HandleLamp
            HandleFan 
            WaitForGoodAir

            state BBB <<fork>> 
              [*] --> BBB 
              BBB --> HandleLamp
              BBB --> HandleFan
              BBB --> WaitForGoodAir

            state AAA <<join>>
              HandleLamp --> AAA
              HandleFan --> AAA
              WaitForGoodAir --> AAA
              AAA --> [*] 
        }
        }
    }
    ''';

void turnFanOn() {}

Future<void> turnLightOn(StateMachine machine) async {
  machine.applyEvent(OnLampOn());
}

Future<void> turnLightOff(StateMachine machine) async {
  machine.applyEvent(OnTurnLampOff());
}

void turnFanOff() {}

class MonitorAir implements State {}

class CleanAir implements State {}

class HandleFan implements State {}

class FanOn implements State {}

class FanOff implements State {}

class HandleLamp implements State {}

class LampOff implements State {}

class LampOn implements State {}

class HandleEquipment implements State {}

class WaitForGoodAir implements State {}

class MaintainAir implements State {}

class OnBadAir implements Event {
  int quality;
}

class OnTurnLampOff implements Event {}

class OnTurnLampOn implements Event {}

class OnLampOn implements Event {}

class OnTurnFanOff implements Event {}

class OnTurnFanOn implements Event {}

class OnFanRunning implements Event {
  int get speed => 6;
}

class OnGoodAir implements Event {}

class TurnOff implements Event {}
