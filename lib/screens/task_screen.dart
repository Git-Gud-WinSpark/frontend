import 'package:another_stepper/another_stepper.dart';
import 'package:custom_timer/custom_timer.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/gemini_chat.dart';
import 'package:frontend/services/completeTask.dart';
import 'package:frontend/services/setSubtaskTime.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({
    super.key,
    required this.subTask,
    required this.done,
    required this.uId,
    required this.coId,
    required this.chId,
    required this.liveID,
  });
  final String uId;
  final String coId;
  final String chId;
  final List<dynamic> subTask;
  final int done;
  final String liveID;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  double currentPercent = 0.0;
  Duration _parseDuration(String timeSpent) {
    final parts = timeSpent.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = double.parse(parts[2]).floor().toInt();
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  late CustomTimerController _controller;
  Duration? duration;
  @override
  void initState() {
    duration = _parseDuration(widget.subTask[_currentIndex]['timeSpent']);
    _controller = CustomTimerController(
        vsync: this,
        begin: duration!,
        end: const Duration(),
        initialState: CustomTimerState.reset,
        interval: CustomTimerInterval.milliseconds);

    _currentIndex = widget.done;
    currentPercent = _currentIndex / widget.subTask.length;
    super.initState();
  }

  void setComplete() async {
    await completeTask(
        token: widget.uId,
        communityID: widget.coId,
        channelID: widget.chId,
        taskID: widget.liveID,
        subID: widget.subTask[_currentIndex]["_id"]);
  }

  void onFinished() async {
    setState(() {
      if (currentPercent < 1) {
        setComplete();
        currentPercent += (1 / widget.subTask.length);
      }
      if (_currentIndex < widget.subTask.length - 1) {
        _currentIndex++;
        duration = _parseDuration(widget.subTask[_currentIndex]['timeSpent']);
        _controller.begin = duration!;
      }
    });
    _controller.reset();
  }

  void setTime(String time) async {
    await setSubtaskTime(
      token: widget.uId,
      communityID: widget.coId,
      channelID: widget.chId,
      taskID: widget.liveID,
      subID: widget.subTask[_currentIndex]["_id"],
      time: time,
    );
  }

  @override
  Widget build(BuildContext context) {
    _controller.state.addListener(() {
      if (_controller.state.value == CustomTimerState.finished) {
        onFinished();
      }
      if (_controller.state.value == CustomTimerState.paused) {
        setTime(_controller.remaining.value.duration.toString());
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Screen'),
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop(_currentIndex);
            },
            icon: const Icon(Icons.arrow_back)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (ctx) => const GeminiChat()));
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20,
            ),
            const Text(
              "Total Progress",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            LinearPercentIndicator(
              alignment: MainAxisAlignment.center,
              width: 300,
              animation: true,
              lineHeight: 20.0,
              animationDuration: 2000,
              percent: currentPercent,
              barRadius: Radius.circular(8),
              progressColor: Colors.blue,
            ),
            Text(
              "${(currentPercent * 100).toStringAsFixed(2)}% Completed",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              "Checklist",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
              child: AnotherStepper(
                activeIndex: _currentIndex,
                stepperList: [
                  for (var index = 0; index < widget.subTask.length; index++)
                    StepperData(
                      title: StepperText(
                        widget.subTask[index]["name"],
                        textStyle: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
                stepperDirection: Axis.vertical,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            CustomTimer(
              controller: _controller,
              builder: (state, time) {
                return Text(
                  "${time.hours}:${time.minutes}:${time.seconds}.${time.milliseconds}",
                  style: const TextStyle(
                    fontSize: 24.0,
                    color: Colors.white,
                  ),
                );
              },
            ),
            SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RoundedButton(
                  text: "Start",
                  color: Colors.green,
                  onPressed: () => _controller.start(),
                ),
                RoundedButton(
                  text: "Pause",
                  color: Colors.blue,
                  onPressed: () => _controller.pause(),
                ),
                RoundedButton(
                  text: "Reset",
                  color: Colors.red,
                  onPressed: () => _controller.reset(),
                ),
                RoundedButton(
                  text: "Finish",
                  color: Colors.red,
                  onPressed: () {
                    onFinished();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RoundedButton extends StatelessWidget {
  final String text;
  final Color color;
  final void Function()? onPressed;

  RoundedButton({required this.text, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
