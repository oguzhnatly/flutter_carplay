// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CPConnectionStatusTypes connectionStatus = CPConnectionStatusTypes.unknown;
  final FlutterCarplay _flutterCarplay = FlutterCarplay();

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Carplay'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
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
                'Carplay Status: ' +
                    CPEnumUtils.stringFromEnum(connectionStatus),
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
                primary: Colors.red,
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
      ),
    );
  }
}
