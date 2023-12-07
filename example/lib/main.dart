// ignore_for_file: avoid_print

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_carplay_example/new_page.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CPConnectionStatusTypes connectionStatus = CPConnectionStatusTypes.unknown;
  final FlutterCarplay _flutterCarplay = FlutterCarplay();

  String voiceControlTranscript = "";

  /// true = voice control recording started and listening, false = not recording
  bool voiceControlStatus = false;

  @override
  void initState() {
    super.initState();

    final List<CPListSection> section1Items = [];
    section1Items.add(CPListSection(
      items: [
        CPListItem(
          text: "Item 1",
          detailText: "Detail Text",
          onPress: (complete, self) {
            self.setDetailText("You can change the detail text.. 🚀");
            self.setAccessoryType(CPListItemAccessoryTypes.cloud);
            Future.delayed(const Duration(seconds: 1), () {
              self.setDetailText("Customizable Detail Text");
              complete();
            });
          },
          image: 'images/logo_flutter_1080px_clr.png',
        ),
        CPListItem(
          text: "Item 2",
          detailText: "Start progress bar",
          isPlaying: false,
          playbackProgress: 0,
          image: 'images/logo_flutter_1080px_clr.png',
          onPress: (complete, self) {
            for (var i = 1; i <= 100; i++) {
              sleep(const Duration(milliseconds: 10));
              self.setPlaybackProgress(i / 100);
              if (i == 100) {
                complete();
              }
            }
          },
        ),
      ],
      header: "First Section",
    ));
    section1Items.add(CPListSection(
      items: [
        CPListItem(
          text: "Item 3",
          detailText: "Detail Text",
          onPress: (complete, self) {
            self.updateTexts(
              text: "You can also change the title",
              detailText: "and detail text while loading",
            );
            self.setAccessoryType(CPListItemAccessoryTypes.none);
            Future.delayed(const Duration(seconds: 1), () {
              complete();
            });
          },
          accessoryType: CPListItemAccessoryTypes.disclosureIndicator,
        ),
        CPListItem(text: "Item 4", detailText: "Detail Text"),
        CPListItem(text: "Item 5", detailText: "Detail Text"),
      ],
      header: "Second Section",
    ));

    final List<CPListSection> section2Items = [];
    section2Items.add(CPListSection(
      items: [
        CPListItem(
          text: "Voice Control",
          detailText: "Displays a voice control indicator during audio input",
          onPress: (complete, self) {
            Future.delayed(Duration.zero, () {
              showVoiceControl(context);
              complete();
            });
          },
        ),
        CPListItem(
          text: "Alert",
          detailText: "Action template that the user can perform on an alert",
          onPress: (complete, self) {
            showAlert();
            complete();
          },
        ),
        CPListItem(
          text: "Grid Template",
          detailText: "A template that displays and manages a grid of items",
          onPress: (complete, self) {
            openGridTemplate();
            complete();
          },
        ),
        CPListItem(
          text: "Action Sheet",
          detailText: "A template that displays a modal action sheet",
          onPress: (complete, self) {
            showActionSheet();
            complete();
          },
        ),
        CPListItem(
          text: "List Template",
          detailText: "Displays and manages a list of items",
          onPress: (complete, self) {
            openListTemplate();
            complete();
          },
        ),
        CPListItem(
          text: "Information Template",
          detailText: "Displays a list of items and up to three actions",
          onPress: (complete, self) {
            openInformationTemplate();
            complete();
          },
        ),
        CPListItem(
          text: "Point Of Interest Template",
          detailText: "Displays a Map with points of interest.",
          onPress: (complete, self) {
            openPoiTemplate();
            complete();
          },
        ),
      ],
      header: "Features",
    ));

    FlutterCarplay.setRootTemplate(
      // rootTemplate: CPMapTemplate(
      //   title: 'Map Template',
      //   mapButtons: [
      //     CPMapButton(
      //       title: 'MB1',
      //       onPress: () => log('MB1 pressed'),
      //     ),
      //     CPMapButton(
      //       title: 'MB2',
      //       onPress: () => log('MB2 pressed'),
      //     ),
      //   ],
      //   leadingNavigationBarButtons: [
      //     CPBarButton(
      //       title: 'LBB1',
      //       onPress: () => log('LBB1 pressed'),
      //     ),
      //     CPBarButton(
      //       title: 'LBB2',
      //       onPress: () => log('LBB2 pressed'),
      //     ),
      //   ],
      //   trailingNavigationBarButtons: [
      //     CPBarButton(
      //       title: 'TBB1',
      //       onPress: () => log('TBB1 pressed'),
      //     ),
      //     CPBarButton(
      //       title: 'TBB2',
      //       onPress: () => log('TBB2 pressed'),
      //     ),
      //   ],
      // ),
      rootTemplate: CPTabBarTemplate(
        templates: [
          CPListTemplate(
            sections: section1Items,
            title: "Home",
            showsTabBadge: false,
            systemIcon: "house.fill",
          ),
          CPListTemplate(
            sections: section2Items,
            title: "Features",
            showsTabBadge: true,
            systemIcon: "star.circle.fill",
          ),
          CPListTemplate(
            sections: [],
            title: "Settings",
            emptyViewTitleVariants: ["Settings"],
            emptyViewSubtitleVariants: [
              "No settings have been added here yet. You can start adding right away"
            ],
            showsTabBadge: false,
            systemIcon: "gear",
          ),
        ],
      ),
      animated: true,
    );

    _flutterCarplay.forceUpdateRootTemplate();

    _flutterCarplay.addListenerOnConnectionChange(onCarplayConnectionChange);
  }

  @override
  void dispose() {
    _flutterCarplay.removeListenerOnConnectionChange();
    super.dispose();
  }

  void onCarplayConnectionChange(CPConnectionStatusTypes status) {
    // Do things when carplay state is connected, background or disconnected
    setState(() {
      connectionStatus = status;
    });
  }

  void showAlert() {
    FlutterCarplay.showAlert(
      template: CPAlertTemplate(
        titleVariants: ["Alert Title"],
        actions: [
          CPAlertAction(
            title: "Okay",
            style: CPAlertActionStyles.normal,
            onPress: () {
              FlutterCarplay.popModal(animated: true);
              print("Okay pressed");
            },
          ),
          CPAlertAction(
            title: "Cancel",
            style: CPAlertActionStyles.cancel,
            onPress: () {
              FlutterCarplay.popModal(animated: true);
              print("Cancel pressed");
            },
          ),
          CPAlertAction(
            title: "Remove",
            style: CPAlertActionStyles.destructive,
            onPress: () {
              FlutterCarplay.popModal(animated: true);
              print("Remove pressed");
            },
          ),
        ],
      ),
    );
  }

  void showActionSheet() {
    FlutterCarplay.showActionSheet(
      template: CPActionSheetTemplate(
        title: "Action Sheet Template",
        message: "This is an example message.",
        actions: [
          CPAlertAction(
            title: "Cancel",
            style: CPAlertActionStyles.cancel,
            onPress: () {
              print("Cancel pressed in action sheet");
              FlutterCarplay.popModal(animated: true);
            },
          ),
          CPAlertAction(
            title: "Dismiss",
            style: CPAlertActionStyles.destructive,
            onPress: () {
              print("Dismiss pressed in action sheet");
              FlutterCarplay.popModal(animated: true);
            },
          ),
          CPAlertAction(
            title: "Ok",
            style: CPAlertActionStyles.normal,
            onPress: () {
              print("Ok pressed in action sheet");
              FlutterCarplay.popModal(animated: true);
            },
          ),
        ],
      ),
    );
  }

  void addNewTemplate(CPListTemplate newTemplate) {
    final currentRootTemplate = FlutterCarplay.rootTemplate!;

    currentRootTemplate.templates.add(newTemplate);

    FlutterCarplay.setRootTemplate(
      rootTemplate: currentRootTemplate,
      animated: true,
    );
    _flutterCarplay.forceUpdateRootTemplate();
  }

  void removeLastTemplate() {
    final currentRootTemplate = FlutterCarplay.rootTemplate!;

    currentRootTemplate.templates.remove(currentRootTemplate.templates.last);

    FlutterCarplay.setRootTemplate(
      rootTemplate: currentRootTemplate,
      animated: true,
    );
    _flutterCarplay.forceUpdateRootTemplate();
  }

  void openGridTemplate() {
    FlutterCarplay.push(
      template: CPGridTemplate(
        title: "Grid Template",
        buttons: [
          for (var i = 1; i < 9; i++)
            CPGridButton(
              titleVariants: ["Item $i"],
              // ----- TRADEMARKS RIGHTS INFORMATION BEGIN -----
              // The official Flutter logo is used from the link below.
              // For more information, please visit and read
              // Flutter Brand Guidelines Website: https://flutter.dev/brand
              //
              // FLUTTER AND THE RELATED LOGO ARE TRADEMARKS OF Google LLC.
              // WE ARE NOT ENDORSED BY OR AFFILIATED WITH Google LLC.
              // ----- TRADEMARKS RIGHTS INFORMATION END -----
              image: 'images/logo_flutter_1080px_clr.png',
              onPress: () {
                print("Grid Button $i pressed");
              },
            ),
        ],
      ),
      animated: true,
    );
  }

  void openListTemplate() {
    FlutterCarplay.push(
      template: CPListTemplate(
        sections: [
          CPListSection(
            header: "A Section",
            items: [
              CPListItem(text: "Item 1"),
              CPListItem(text: "Item 2"),
              CPListItem(text: "Item 3"),
              CPListItem(text: "Item 4"),
            ],
          ),
          CPListSection(
            header: "B Section",
            items: [
              CPListItem(text: "Item 5"),
              CPListItem(text: "Item 6"),
            ],
          ),
          CPListSection(
            header: "C Section",
            items: [
              CPListItem(text: "Item 7"),
              CPListItem(text: "Item 8"),
            ],
          ),
        ],
        systemIcon: "systemIcon",
        title: "List Template",
        backButton: CPBarButton(
          title: "Back",
          style: CPBarButtonStyles.none,
          onPress: () {
            FlutterCarplay.pop(animated: true);
          },
        ),
      ),
      animated: true,
    );
  }

  void openInformationTemplate() {
    FlutterCarplay.push(
        template: CPInformationTemplate(
            title: "Title",
            layout: CPInformationTemplateLayout.twoColumn,
            actions: [
          CPTextButton(
              title: "Button Title 1",
              onPress: () {
                print("Button 1");
              }),
          CPTextButton(
              title: "Button Title 2",
              onPress: () {
                print("Button 2");
              }),
        ],
            informationItems: [
          CPInformationItem(title: "Item title 1", detail: "detail 1"),
          CPInformationItem(title: "Item title 2", detail: "detail 2"),
          CPInformationItem(title: "Item title 3", detail: "detail 3"),
          CPInformationItem(title: "Item title 4", detail: "detail 4"),
          CPInformationItem(title: "Item title 5", detail: "detail 5"),
          CPInformationItem(title: "Item title 6", detail: "detail 6"),
          CPInformationItem(title: "Item title 7", detail: "detail 7"),
          CPInformationItem(title: "Item title 8", detail: "detail 8"),
          CPInformationItem(title: "Item title 9", detail: "detail 9"),
          CPInformationItem(title: "Item title 10", detail: "detail 10"),
        ]));
  }

  void openPoiTemplate() {
    FlutterCarplay.push(
        template: CPPointOfInterestTemplate(title: "Title", poi: [
          CPPointOfInterest(
            latitude: 51.5052,
            longitude: 7.4938,
            title: "Title",
            subtitle: "Subtitle",
            summary: "Summary",
            detailTitle: "DetailTitle",
            detailSubtitle: "detailSubtitle",
            detailSummary: "detailSummary",
            image: "images/logo_flutter_1080px_clr.png",
            primaryButton: CPTextButton(
                title: "Primary",
                onPress: () {
                  print("Primary button pressed");
                }),
            secondaryButton: CPTextButton(
                title: "Secondary",
                onPress: () {
                  print("Secondary button pressed");
                }),
          ),
        ]),
        animated: true);
  }

  void showVoiceControl(BuildContext context) {
    /// Clearing previous transcript and sets the status as started.
    setState(() {
      voiceControlStatus = false;
      voiceControlTranscript = "";
    });

    /// Displaying voice control to CarPlay.
    FlutterCarplay.showVoiceControl(
      template: CPVoiceControlTemplate(
        locale: const Locale('en', 'US'),
        voiceControlStates: [
          CPVoiceControlState(
            titleVariants: ["Example Voice Control"],
            image: "images/voice_recognition_animated_image.gif",
            identifier: "test",
          ),
        ],
      ),
    );

    /// Greet the user with a localized speech from a text.
    FlutterCarplay.speak(CPSpeaker(
      text:
          "Welcome to voice control. To stop, you can say stop the voice control.",
      language: const Locale('en', 'US'),
    ));

    /// [DISCLAIMER]
    /// THE DIALOG IS USED FOR EXAMPLE-ONLY IN ORDER TO
    /// INTRODUCE ALL ACTIONS OF THIS PACKAGE BETTER.
    /// YOU SHOULD NEVER SHOW ANY DIALOG OR ALERT TO
    /// ANY USER'S OR ESPECIALLY ANY DRIVER'S PHONE.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Voice Control System"),
          actions: [
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    voiceControlStatus == false
                        ? const Text(
                            "You can start or stop voice control anytime. Currently, voice control is not listening you.",
                            textAlign: TextAlign.center,
                          )
                        : const Text(
                            "Voice control is listening, you can start talking. It will be shown below.",
                            textAlign: TextAlign.center,
                          ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: voiceControlTranscript != ""
                          ? Text("Transcript: " + voiceControlTranscript)
                          : const SizedBox(),
                    ),
                    voiceControlStatus == false
                        ? TextButton(
                            onPressed: () => startVoiceControl(setState),
                            child: const Text("Start Recording"),
                          )
                        : TextButton(
                            onPressed: () => endVoiceControl(setState),
                            child: const Text("Stop Recording"),
                          ),
                    TextButton(
                      onPressed: () {
                        if (voiceControlStatus == true) {
                          setState(() {
                            voiceControlStatus = false;
                          });
                          FlutterCarplay.stopVoiceControl();
                          FlutterCarplay
                              .removeListenerOnSpeechRecognitionTranscriptChange();
                        }
                        setState(() {
                          voiceControlTranscript = "";
                        });
                        Navigator.of(context).pop();
                        FlutterCarplay.speak(CPSpeaker(
                          text: "Voice control is stopping.",
                          language: const Locale('en', 'US'),
                          onComplete: () => FlutterCarplay.popModal(),
                        ));
                      },
                      child: const Text('Close Voice Control'),
                    ),
                  ],
                );
              },
            )
          ],
        );
      },
    );
  }

  void startVoiceControl(void Function(void Function()) setState) {
    if (voiceControlStatus == false) {
      /// Play a sound to signal the user to begin speaking
      FlutterCarplay.play(CPAudio(
        soundPath: 'musics/ping_sound_effect.mp3',
        volume: 1.0,
      ));
      FlutterCarplay.startVoiceControl();
      setState(() {
        voiceControlStatus = true;
        voiceControlTranscript = "";
      });
      FlutterCarplay.addListenerOnSpeechRecognitionTranscriptChange(
        onSpeechRecognitionTranscriptChange: (transcript) {
          log('Transcript: $transcript');
          setState(() {
            voiceControlTranscript = transcript;
          });
          checkVoiceControlTranscript(
            transcript: transcript,
            inModal: true,
          );
        },
      );
    }
  }

  void endVoiceControl(void Function(void Function()) setState) {
    if (voiceControlStatus == true) {
      FlutterCarplay.speak(CPSpeaker(
        text: "You said that, " + voiceControlTranscript,
        language: const Locale('en', 'US'),
      ));
      setState(() {
        voiceControlStatus = false;
      });
      FlutterCarplay.stopVoiceControl();
      FlutterCarplay.removeListenerOnSpeechRecognitionTranscriptChange();
    }
  }

  void checkVoiceControlTranscript({
    required String transcript,
    bool inModal = false,
  }) {
    if (transcript.toUpperCase().contains('STOP THE VOICE CONTROL')) {
      setState(() {
        voiceControlStatus = false;
        voiceControlTranscript = "";
      });
      FlutterCarplay.stopVoiceControl();
      FlutterCarplay.removeListenerOnSpeechRecognitionTranscriptChange();
      FlutterCarplay.speak(CPSpeaker(
        text: "Okay, voice control is stopping.",
        language: const Locale('en', 'US'),
        onComplete: () => FlutterCarplay.popModal(),
      ));
      if (inModal) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Carplay'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Builder(builder: (context) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 15),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const NewPage()));
              },
              child: const Text('New Page'),
            );
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 15),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                onPressed: () => addNewTemplate(
                  CPListTemplate(
                    sections: [],
                    title: "Blank Screen",
                    emptyViewTitleVariants: ["Blank Screen Example"],
                    emptyViewSubtitleVariants: [
                      "You've just added a blank screen to carplay from your iphone.",
                    ],
                    showsTabBadge: true,
                    systemIcon: "airpods",
                  ),
                ),
                child: const Text(
                  'Add blank\nscreen',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 20, height: 0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 15),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                onPressed: () => removeLastTemplate(),
                child: const Text(
                  'Remove last\nscreen',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              'Carplay Status: ' + CPEnumUtils.stringFromEnum(connectionStatus),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 15),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                onPressed: () => showAlert(),
                child: const Text('Alert'),
              ),
              const SizedBox(width: 15, height: 0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 15),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                onPressed: () => showActionSheet(),
                child: const Text('Action Sheet'),
              ),
              const SizedBox(width: 15, height: 0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 15),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                onPressed: () => FlutterCarplay.popModal(animated: true),
                child: const Text('Close Modal'),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 15),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                onPressed: () => FlutterCarplay.pop(animated: true),
                child: const Text('Pop Screen'),
              ),
              const SizedBox(width: 20, height: 0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 15),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                onPressed: () => FlutterCarplay.popToRoot(animated: true),
                child: const Text('Pop To Root'),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 15),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                onPressed: () => openListTemplate(),
                child: const Text('Open List\nTemplate'),
              ),
              const SizedBox(width: 20, height: 0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 15),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                onPressed: () => openGridTemplate(),
                child: const Text('Open Grid\nTemplate'),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 15),
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 24,
              ),
            ),
            onPressed: () => _flutterCarplay.forceUpdateRootTemplate(),
            child: const Text('Force Update Carplay'),
          ),
          const SizedBox(width: 50, height: 0),
        ],
      ),
    );
  }
}
