import 'state_of_mind.dart';
import 'types.dart';
import 'package:stacktrace_impl/stacktrace_impl.dart';

class Tracker {
  StackTraceImpl stackTrace;

  StateOfMind stateOfMind;
  Event transitionedBy;

  Tracker(this.stateOfMind, this.transitionedBy) {
    stackTrace = StackTraceImpl(skipFrames: 1);
  }
}
