// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_carplay/controllers/android_auto_controller.dart';
import 'package:flutter_carplay/controllers/carplay_controller.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ConnectionStatusTypes connectionStatus = ConnectionStatusTypes.unknown;
  final FlutterCarplay _flutterCarplay = FlutterCarplay();
  final FlutterAndroidAuto _flutterAndroidAuto = FlutterAndroidAuto();

  @override
  void initState() {
    super.initState();

    if (Platform.isIOS) {
      setupCarplay();
    } else if (Platform.isAndroid) {
      setupAndroidAuto();
    }
  }

  void setupCarplay() {
    _flutterCarplay.addListenerOnConnectionChange(onConnectionChange);
    setInitialCarplayRootTemplate();
  }

  void setInitialCarplayRootTemplate() {
    final List<CPListSection> section1Items = [];
    section1Items.add(CPListSection(
      items: [
        CPListItem(
          text: 'Item 1',
          detailText: 'Detail Text',
          onPress: (complete, self) {
            self.setDetailText('You can change the detail text.. 🚀');
            self.setAccessoryType(CPListItemAccessoryType.cloud);
            Future.delayed(const Duration(seconds: 1), () {
              self.setDetailText('Customizable Detail Text');
              complete();
            });
          },
          image: 'images/logo_flutter_1080px_clr.png',
        ),
        CPListItem(
          text: 'Item 2',
          detailText: 'Start progress bar',
          isPlaying: false,
          playbackProgress: 0,
          image: 'images/icon.svg',
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
      header: 'First Section',
    ));
    section1Items.add(CPListSection(
      items: [
        CPListItem(
          text: 'Item 3',
          detailText: 'Detail Text',
          onPress: (complete, self) {
            self.update(
              text: 'You can also change the title',
              detailText: 'and detail text while loading',
            );
            self.setAccessoryType(CPListItemAccessoryType.none);
            Future.delayed(const Duration(seconds: 1), () {
              complete();
            });
          },
          accessoryType: CPListItemAccessoryType.disclosureIndicator,
        ),
        CPListItem(text: 'Item 4', detailText: 'Detail Text'),
        CPListItem(text: 'Item 5', detailText: 'Detail Text'),
      ],
      header: 'Second Section',
    ));

    final List<CPListSection> section2Items = [];
    section2Items.add(CPListSection(
      items: [
        CPListItem(
          text: 'Alert',
          detailText: 'Action template that the user can perform on an alert',
          onPress: (complete, self) {
            showAlert();
            complete();
          },
        ),
        CPListItem(
          text: 'Grid Template',
          detailText: 'A template that displays and manages a grid of items',
          onPress: (complete, self) {
            openGridTemplate();
            complete();
          },
        ),
        CPListItem(
          text: 'Action Sheet',
          detailText: 'A template that displays a modal action sheet',
          onPress: (complete, self) {
            showActionSheet();
            complete();
          },
        ),
        CPListItem(
          text: 'List Template',
          detailText: 'Displays and manages a list of items',
          onPress: (complete, self) {
            openListTemplate();
            complete();
          },
        ),
        CPListItem(
          text: 'Information Template',
          detailText: 'Displays a list of items and up to three actions',
          onPress: (complete, self) {
            openInformationTemplate();
            complete();
          },
        ),
        CPListItem(
          text: 'Point Of Interest Template',
          detailText: 'Displays a Map with points of interest.',
          onPress: (complete, self) {
            openPoiTemplate();
            complete();
          },
        ),
        CPListItem(
          text: 'SVG Examples',
          detailText: 'Rows, grid buttons, POI, and image rows.',
          image: 'images/svg_navigation.svg',
          onPress: (complete, self) {
            openSvgExamplesTemplate();
            complete();
          },
        ),
        CPListItem(
          text: 'Image Tint Examples',
          detailText: 'Platform, standard, and custom icon tints.',
          image: 'images/svg_media_glyph.svg',
          imageTint: const AutoImageTint.platform(),
          onPress: (complete, self) {
            openImageTintExamplesTemplate();
            complete();
          },
        ),
      ],
      header: 'Features',
    ));

    FlutterCarplay.setRootTemplate(
      rootTemplate: CPTabBarTemplate(
        templates: [
          CPListTemplate(
            sections: section1Items,
            title: 'Home',
            systemIcon: 'house.fill',
          ),
          CPListTemplate(
            sections: section2Items,
            title: 'Features',
            showsTabBadge: true,
            systemIcon: 'star.circle.fill',
          ),
          CPListTemplate(
            sections: [],
            title: 'Settings',
            emptyViewTitleVariants: ['Settings'],
            emptyViewSubtitleVariants: [
              'No settings have been added here yet. You can start adding right away'
            ],
            systemIcon: 'gear',
          ),
        ],
      ),
    );

    _flutterCarplay.forceUpdateRootTemplate();
  }

  @override
  void dispose() {
    _flutterCarplay.removeListenerOnConnectionChange();
    super.dispose();
  }

  void onConnectionChange(ConnectionStatusTypes status) {
    // Do things when carplay/android auto state is connected, background or disconnected
    setState(() {
      connectionStatus = status;
    });
  }

  void setupAndroidAuto() {
    _flutterAndroidAuto.addListenerOnConnectionChange(onConnectionChange);
    setInitialAndroidAutoRootTemplate();
  }

  void setInitialAndroidAutoRootTemplate() {
    FlutterAndroidAuto.setRootTemplate(
      template: AAListTemplate(
        title: 'Home',
        sections: [
          AAListSection(
            title: 'First Section',
            items: [
              AAListItem(
                title: 'Page 1',
                subtitle: 'Click to open page 1',
                imageUrl: 'images/icon.svg',
                onPress: (complete, AAListItem item) {
                  print('Item for Page 1 pressed');
                  FlutterAndroidAuto.push(
                    template: AAListTemplate(
                      title: 'Page 1',
                      sections: [
                        AAListSection(
                          items: [
                            AAListItem(
                              title: 'Item 1',
                              subtitle: 'Click to pop',
                              imageUrl:
                                  'https://storage.googleapis.com/cms-storage-bucket/icon_flutter.0dbfcc7a59cd1cf16282.png',
                              onPress: (complete, AAListItem item) {
                                FlutterAndroidAuto.pop();
                                complete();
                              },
                            ),
                            AAListItem(
                              title: 'Page 2',
                              subtitle: 'Click to open page 2',
                              imageUrl:
                                  'https://storage.googleapis.com/cms-storage-bucket/icon_flutter.0dbfcc7a59cd1cf16282.png',
                              onPress: (complete, AAListItem item) {
                                print('Item for Page 2 pressed');
                                FlutterAndroidAuto.push(
                                  template: AAListTemplate(
                                    title: 'Page 2',
                                    sections: [
                                      AAListSection(
                                        items: [
                                          AAListItem(
                                            title: 'Item 1',
                                            subtitle: 'Click to pop',
                                            imageUrl:
                                                'https://storage.googleapis.com/cms-storage-bucket/icon_flutter.0dbfcc7a59cd1cf16282.png',
                                            onPress:
                                                (complete, AAListItem item) {
                                              FlutterAndroidAuto.pop();
                                              complete();
                                            },
                                          ),
                                          AAListItem(
                                            title: 'Page 2',
                                            subtitle:
                                                'Click to open pop to root',
                                            imageUrl:
                                                'https://storage.googleapis.com/cms-storage-bucket/icon_flutter.0dbfcc7a59cd1cf16282.png',
                                            onPress:
                                                (complete, AAListItem item) {
                                              FlutterAndroidAuto.popToRoot();
                                              complete();
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                                complete();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                  complete();
                },
              ),
              AAListItem(
                title: 'SVG Examples',
                subtitle: 'Open Android Auto rows backed by SVG assets',
                imageUrl: 'images/svg_navigation.svg',
                onPress: (complete, AAListItem item) {
                  openSvgExamplesTemplate();
                  complete();
                },
              ),
              AAListItem(
                title: 'Image Tint Examples',
                subtitle: 'Platform, standard, and custom icon tints',
                imageUrl: 'images/svg_media_glyph.svg',
                imageTint: const AutoImageTint.platform(),
                onPress: (complete, AAListItem item) {
                  openImageTintExamplesTemplate();
                  complete();
                },
              ),
            ],
          ),
          AAListSection(
            title: 'Second Section',
            items: [
              AAListItem(title: 'Test'),
            ],
          ),
        ],
      ),
    );
    _flutterAndroidAuto.forceUpdateRootTemplate();
  }

  void showAlert() {
    if (!Platform.isIOS) {
      print('This example has not been yet updated for Android');
      return;
    }

    FlutterCarplay.showAlert(
      template: CPAlertTemplate(
        titleVariants: ['Alert Title'],
        actions: [
          CPAlertAction(
            title: 'Okay',
            onPress: () {
              FlutterCarplay.popModal();
              print('Okay pressed');
            },
          ),
          CPAlertAction(
            title: 'Cancel',
            style: CPAlertActionStyle.cancel,
            onPress: () {
              FlutterCarplay.popModal();
              print('Cancel pressed');
            },
          ),
          CPAlertAction(
            title: 'Remove',
            style: CPAlertActionStyle.destructive,
            onPress: () {
              FlutterCarplay.popModal();
              print('Remove pressed');
            },
          ),
        ],
      ),
    );
  }

  void showActionSheet() {
    if (!Platform.isIOS) {
      print('This example has not been yet updated for Android');
      return;
    }

    FlutterCarplay.showActionSheet(
      template: CPActionSheetTemplate(
        title: 'Action Sheet Template',
        message: 'This is an example message.',
        actions: [
          CPAlertAction(
            title: 'Cancel',
            style: CPAlertActionStyle.cancel,
            onPress: () {
              print('Cancel pressed in action sheet');
              FlutterCarplay.popModal();
            },
          ),
          CPAlertAction(
            title: 'Dismiss',
            style: CPAlertActionStyle.destructive,
            onPress: () {
              print('Dismiss pressed in action sheet');
              FlutterCarplay.popModal();
            },
          ),
          CPAlertAction(
            title: 'Ok',
            onPress: () {
              print('Ok pressed in action sheet');
              FlutterCarplay.popModal();
            },
          ),
        ],
      ),
    );
  }

  void addNewTemplate(CPListTemplate newTemplate) {
    if (!Platform.isIOS) {
      print('This example has not been yet updated for Android');
      return;
    }

    final currentRootTemplate = FlutterCarplay.rootTemplate!;

    currentRootTemplate.templates.add(newTemplate);

    FlutterCarplay.setRootTemplate(
      rootTemplate: currentRootTemplate,
    );
    _flutterCarplay.forceUpdateRootTemplate();
  }

  void setBlankRootTemplate() {
    if (Platform.isIOS) {
      FlutterCarplay.setRootTemplate(
        rootTemplate: CPListTemplate(
          sections: [],
          title: 'Blank Screen',
          emptyViewTitleVariants: ['Blank Screen Example'],
          emptyViewSubtitleVariants: [
            "You've just added a blank screen to carplay from your iphone.",
          ],
          showsTabBadge: true,
          systemIcon: 'airpods',
        ),
      );
      _flutterCarplay.forceUpdateRootTemplate();
    } else {
      FlutterAndroidAuto.setRootTemplate(
        template: AAListTemplate(
          title: 'Blank Screen',
          sections: [],
        ),
      );
      _flutterAndroidAuto.forceUpdateRootTemplate();
    }
  }

  void removeLastTemplate() {
    if (!Platform.isIOS) {
      print('This example has not been yet updated for Android');
      return;
    }

    final currentRootTemplate = FlutterCarplay.rootTemplate!;

    currentRootTemplate.templates.remove(currentRootTemplate.templates.last);

    FlutterCarplay.setRootTemplate(
      rootTemplate: currentRootTemplate,
    );
    _flutterCarplay.forceUpdateRootTemplate();
  }

  void openGridTemplate() {
    if (!Platform.isIOS) {
      print('This example has not been yet updated for Android');
      return;
    }

    FlutterCarplay.push(
      template: CPGridTemplate(
        title: 'Grid Template',
        buttons: [
          for (var i = 1; i < 9; i++)
            CPGridButton(
              titleVariants: ['Item $i'],
              // ----- TRADEMARKS RIGHTS INFORMATION BEGIN -----
              // The official Flutter logo is used from the link below.
              // For more information, please visit and read
              // Flutter Brand Guidelines Website: https://flutter.dev/brand
              //
              // FLUTTER AND THE RELATED LOGO ARE TRADEMARKS OF Google LLC.
              // WE ARE NOT ENDORSED BY OR AFFILIATED WITH Google LLC.
              // ----- TRADEMARKS RIGHTS INFORMATION END -----
              //
              // Using asset, SVG asset, and network images for demonstration
              // purposes. SVG assets are rasterized to PNG before being sent to
              // the native side.
              image: switch (i % 3) {
                0 =>
                  'https://storage.googleapis.com/cms-storage-bucket/icon_flutter.0dbfcc7a59cd1cf16282.png',
                1 => 'images/icon.svg',
                _ => 'images/logo_flutter_1080px_clr.png',
              },
              onPress: () {
                print('Grid Button $i pressed');
              },
            ),
        ],
        systemIcon: 'systemIcon',
      ),
    );
  }

  void openSvgExamplesTemplate() {
    if (Platform.isIOS) {
      FlutterCarplay.push(
        template: CPListTemplate(
          title: 'SVG Examples',
          sections: [
            CPListSection(
              header: 'Template Examples',
              items: [
                CPListItem(
                  text: 'SVG List Item',
                  detailText: 'CPListItem.image uses an SVG asset',
                  image: 'images/svg_navigation.svg',
                  onPress: (complete, self) {
                    complete();
                  },
                ),
                CPListItem(
                  text: 'SVG Grid Template',
                  detailText: 'CPGridTemplate with SVG CPGridButton images',
                  image: 'images/svg_media.svg',
                  onPress: (complete, self) {
                    openSvgGridTemplate();
                    complete();
                  },
                ),
                CPListItem(
                  text: 'SVG POI Template',
                  detailText: 'CPPointOfInterest.image uses SVG assets',
                  image: 'images/svg_poi.svg',
                  onPress: (complete, self) {
                    openSvgPoiTemplate();
                    complete();
                  },
                ),
              ],
            ),
            CPListSection(
              header: 'Image Row and Grid Elements',
              items: [
                CPListImageRowItem(
                  text: 'Legacy gridImages SVG layout',
                  gridImages: const [
                    'images/svg_navigation.svg',
                    'images/svg_media.svg',
                    'images/svg_poi.svg',
                    'images/svg_warning.svg',
                  ],
                  imageTitles: const ['Nav', 'Media', 'POI', 'Alert'],
                  onItemPress: (complete, self, index) {
                    print('SVG image row item $index pressed');
                    complete();
                  },
                ),
                CPListImageRowItem(
                  text: 'iOS 26 grid/card/row SVG elements',
                  elements: [
                    CPListImageRowItemCardElement(
                      image: 'images/svg_navigation.svg',
                      title: 'Navigate',
                      subtitle: 'Card element',
                    ),
                    CPListImageRowItemGridElement(
                      image: 'images/svg_media.svg',
                    ),
                    CPListImageRowItemImageGridElement(
                      image: 'images/svg_poi.svg',
                      title: 'POI',
                      accessorySymbolName: 'mappin.circle.fill',
                    ),
                    CPListImageRowItemRowElement(
                      image: 'images/svg_warning.svg',
                      title: 'Warning',
                      subtitle: 'Row element',
                    ),
                  ],
                  allowsMultipleLines: true,
                ),
              ],
            ),
          ],
          systemIcon: 'photo.stack',
        ),
      );
    } else if (Platform.isAndroid) {
      FlutterAndroidAuto.push(
        template: AAListTemplate(
          title: 'SVG Examples',
          sections: [
            AAListSection(
              title: 'Android Auto SVG Rows',
              items: [
                AAListItem(
                  title: 'Navigation SVG',
                  subtitle: 'AAListItem.imageUrl asset SVG',
                  imageUrl: 'images/svg_navigation.svg',
                ),
                AAListItem(
                  title: 'Media SVG',
                  subtitle: 'A second SVG asset for row rendering',
                  imageUrl: 'images/svg_media.svg',
                ),
                AAListItem(
                  title: 'Point of Interest SVG',
                  subtitle: 'A map marker styled SVG asset',
                  imageUrl: 'images/svg_poi.svg',
                ),
                AAListItem(
                  title: 'Warning SVG',
                  subtitle: 'High contrast SVG asset',
                  imageUrl: 'images/svg_warning.svg',
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  void openImageTintExamplesTemplate() {
    const customPurpleTint = AutoImageTint.custom(
      color: UIColor(red: 129, green: 83, blue: 255),
      darkColor: UIColor(red: 196, green: 181, blue: 253),
    );

    if (Platform.isIOS) {
      FlutterCarplay.push(
        template: CPListTemplate(
          title: 'Image Tints',
          sections: [
            CPListSection(
              header: 'CarPlay List Items',
              items: [
                CPListItem(
                  text: 'Platform tint',
                  detailText: 'Host-style color with selected-safe contrast',
                  image: 'images/svg_navigation_glyph.svg',
                  imageTint: const AutoImageTint.platform(),
                ),
                CPListItem(
                  text: 'Blue tint',
                  detailText: 'Standard blue glyph tint',
                  image: 'images/svg_media_glyph.svg',
                  imageTint: const AutoImageTint.blue(),
                ),
                CPListItem(
                  text: 'Green tint',
                  detailText: 'Standard green glyph tint',
                  image: 'images/svg_poi_glyph.svg',
                  imageTint: const AutoImageTint.green(),
                ),
                CPListItem(
                  text: 'Custom purple tint',
                  detailText: 'Separate light and dark tint colors',
                  image: 'images/svg_warning_glyph.svg',
                  imageTint: customPurpleTint,
                ),
                CPListItem(
                  text: 'Yellow without safety halo',
                  detailText: 'Shows why selected-safe contrast can matter',
                  image: 'images/svg_warning_glyph.svg',
                  imageTint: const AutoImageTint.yellow(selectedSafe: false),
                ),
                CPListItem(
                  text: 'Tinted Grid Template',
                  detailText: 'CPGridButton images with different tints',
                  image: 'images/svg_media_glyph.svg',
                  imageTint: const AutoImageTint.secondary(),
                  onPress: (complete, self) {
                    openTintedGridTemplate();
                    complete();
                  },
                ),
                CPListItem(
                  text: 'Tinted POI Template',
                  detailText: 'CPPointOfInterest pin images with tints',
                  image: 'images/svg_poi_glyph.svg',
                  imageTint: const AutoImageTint.red(),
                  onPress: (complete, self) {
                    openTintedPoiTemplate();
                    complete();
                  },
                ),
              ],
            ),
            CPListSection(
              header: 'iOS 26 Elements',
              items: [
                CPListImageRowItem(
                  text: 'Legacy tinted gridImages row',
                  gridImages: const [
                    'images/svg_navigation_glyph.svg',
                    'images/svg_media_glyph.svg',
                    'images/svg_poi_glyph.svg',
                    'images/svg_warning_glyph.svg',
                  ],
                  gridImageTints: const [
                    AutoImageTint.platform(),
                    AutoImageTint.blue(),
                    AutoImageTint.green(),
                    AutoImageTint.yellow(),
                  ],
                  imageTitles: const ['Host', 'Blue', 'Green', 'Yellow'],
                ),
                CPListImageRowItem(
                  text: 'Tinted iOS 26 elements',
                  elements: [
                    CPListImageRowItemCardElement(
                      image: 'images/svg_navigation_glyph.svg',
                      imageTint: const AutoImageTint.blue(),
                      title: 'Blue',
                      subtitle: 'Card',
                    ),
                    CPListImageRowItemGridElement(
                      image: 'images/svg_media_glyph.svg',
                      imageTint: const AutoImageTint.green(),
                    ),
                    CPListImageRowItemImageGridElement(
                      image: 'images/svg_poi_glyph.svg',
                      imageTint: customPurpleTint,
                      title: 'Purple',
                      accessorySymbolName: 'paintpalette.fill',
                    ),
                    CPListImageRowItemRowElement(
                      image: 'images/svg_warning_glyph.svg',
                      imageTint: const AutoImageTint.yellow(),
                      title: 'Yellow',
                      subtitle: 'Row',
                    ),
                  ],
                  allowsMultipleLines: true,
                ),
              ],
            ),
          ],
          systemIcon: 'paintpalette',
        ),
      );
    } else if (Platform.isAndroid) {
      FlutterAndroidAuto.push(
        template: AAListTemplate(
          title: 'Image Tints',
          sections: [
            AAListSection(
              title: 'Android Auto Rows',
              items: [
                AAListItem(
                  title: 'Platform tint',
                  subtitle: 'CarColor.DEFAULT lets the host pick contrast',
                  imageUrl: 'images/svg_navigation_glyph.svg',
                  imageTint: const AutoImageTint.platform(),
                ),
                AAListItem(
                  title: 'Blue tint',
                  subtitle: 'Standard CarColor.BLUE',
                  imageUrl: 'images/svg_media_glyph.svg',
                  imageTint: const AutoImageTint.blue(),
                ),
                AAListItem(
                  title: 'Green tint',
                  subtitle: 'Standard CarColor.GREEN',
                  imageUrl: 'images/svg_poi_glyph.svg',
                  imageTint: const AutoImageTint.green(),
                ),
                AAListItem(
                  title: 'Custom purple tint',
                  subtitle: 'Custom light and dark CarColor variants',
                  imageUrl: 'images/svg_warning_glyph.svg',
                  imageTint: customPurpleTint,
                ),
                AAListItem(
                  title: 'Yellow tint',
                  subtitle: 'Standard CarColor.YELLOW',
                  imageUrl: 'images/svg_warning_glyph.svg',
                  imageTint: const AutoImageTint.yellow(),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  void openTintedGridTemplate() {
    FlutterCarplay.push(
      template: CPGridTemplate(
        title: 'Tinted Grid',
        buttons: [
          CPGridButton(
            titleVariants: ['Platform'],
            image: 'images/svg_navigation_glyph.svg',
            imageTint: const AutoImageTint.platform(),
          ),
          CPGridButton(
            titleVariants: ['Blue'],
            image: 'images/svg_media_glyph.svg',
            imageTint: const AutoImageTint.blue(),
          ),
          CPGridButton(
            titleVariants: ['Green'],
            image: 'images/svg_poi_glyph.svg',
            imageTint: const AutoImageTint.green(),
          ),
          CPGridButton(
            titleVariants: ['Purple'],
            image: 'images/svg_warning_glyph.svg',
            imageTint: const AutoImageTint.custom(
              color: UIColor(red: 129, green: 83, blue: 255),
              darkColor: UIColor(red: 196, green: 181, blue: 253),
            ),
          ),
        ],
        systemIcon: 'paintpalette',
      ),
    );
  }

  void openTintedPoiTemplate() {
    FlutterCarplay.push(
      template: CPPointOfInterestTemplate(
        title: 'Tinted POI',
        poi: [
          CPPointOfInterest(
            latitude: 51.5052,
            longitude: 7.4938,
            title: 'Blue Pin',
            subtitle: 'Tinted SVG pin image',
            summary: 'Uses AutoImageTint.blue',
            detailTitle: 'Blue Pin',
            detailSubtitle: 'Tinted POI example',
            detailSummary: 'The pin image is pre-rendered on CarPlay.',
            image: 'images/svg_poi_glyph.svg',
            imageTint: const AutoImageTint.blue(),
          ),
          CPPointOfInterest(
            latitude: 51.5074,
            longitude: 7.4970,
            title: 'Red Warning',
            subtitle: 'Tinted warning marker',
            summary: 'Uses AutoImageTint.red',
            detailTitle: 'Red Warning',
            detailSubtitle: 'Tinted POI example',
            detailSummary: 'The pin image keeps selected-safe contrast.',
            image: 'images/svg_warning_glyph.svg',
            imageTint: const AutoImageTint.red(),
          ),
        ],
      ),
    );
  }

  void openSvgGridTemplate() {
    FlutterCarplay.push(
      template: CPGridTemplate(
        title: 'SVG Grid',
        buttons: [
          CPGridButton(
            titleVariants: ['Navigation'],
            image: 'images/svg_navigation.svg',
            onPress: () => print('Navigation SVG grid button pressed'),
          ),
          CPGridButton(
            titleVariants: ['Media'],
            image: 'images/svg_media.svg',
            onPress: () => print('Media SVG grid button pressed'),
          ),
          CPGridButton(
            titleVariants: ['POI'],
            image: 'images/svg_poi.svg',
            onPress: () => print('POI SVG grid button pressed'),
          ),
          CPGridButton(
            titleVariants: ['Warning'],
            image: 'images/svg_warning.svg',
            onPress: () => print('Warning SVG grid button pressed'),
          ),
        ],
        systemIcon: 'square.grid.2x2',
      ),
    );
  }

  void openSvgPoiTemplate() {
    FlutterCarplay.push(
      template: CPPointOfInterestTemplate(
        title: 'SVG POI',
        poi: [
          CPPointOfInterest(
            latitude: 51.5052,
            longitude: 7.4938,
            title: 'SVG Cafe',
            subtitle: 'POI marker SVG',
            summary: 'Uses images/svg_poi.svg',
            detailTitle: 'SVG Cafe',
            detailSubtitle: 'Rasterized before native display',
            detailSummary: 'Point-of-interest template image example',
            image: 'images/svg_poi.svg',
          ),
          CPPointOfInterest(
            latitude: 51.5074,
            longitude: 7.4970,
            title: 'SVG Warning Zone',
            subtitle: 'Warning marker SVG',
            summary: 'Uses images/svg_warning.svg',
            detailTitle: 'SVG Warning Zone',
            detailSubtitle: 'Rasterized before native display',
            detailSummary: 'Second point-of-interest SVG example',
            image: 'images/svg_warning.svg',
          ),
        ],
      ),
    );
  }

  void openListTemplate() {
    if (Platform.isIOS) {
      FlutterCarplay.push(
        template: CPListTemplate(
          sections: [
            CPListSection(
              header: 'A Section',
              items: [
                CPListItem(text: 'Item 1'),
                CPListItem(text: 'Item 2'),
                CPListItem(text: 'Item 3'),
                CPListItem(text: 'Item 4'),
              ],
            ),
            CPListSection(
              header: 'B Section',
              items: [
                CPListItem(text: 'Item 5'),
                CPListItem(text: 'Item 6'),
              ],
            ),
            CPListSection(
              header: 'C Section',
              items: [
                CPListItem(text: 'Item 7'),
                CPListItem(text: 'Item 8'),
              ],
            ),
          ],
          systemIcon: 'systemIcon',
          title: 'List Template',
          backButton: CPBarButton(
            title: 'Back',
            buttonStyle: CPBarButtonStyle.none,
            onPress: () {
              FlutterCarplay.pop();
            },
          ),
        ),
      );
    } else if (Platform.isAndroid) {
      FlutterAndroidAuto.push(
        template: AAListTemplate(
          title: 'List Template',
          sections: [
            AAListSection(
              title: 'A Section',
              items: [
                AAListItem(title: 'Item 1'),
                AAListItem(title: 'Item 2'),
                AAListItem(title: 'Item 3'),
                AAListItem(title: 'Item 4'),
              ],
            ),
            AAListSection(
              title: 'B Section',
              items: [
                AAListItem(title: 'Item 5'),
                AAListItem(title: 'Item 6'),
              ],
            ),
            AAListSection(
              title: 'C Section',
              items: [
                AAListItem(title: 'Item 7'),
                AAListItem(title: 'Item 8'),
              ],
            ),
          ],
        ),
      );
    }
  }

  void openInformationTemplate() {
    FlutterCarplay.push(
        template: CPInformationTemplate(
            title: 'Title',
            layout: CPInformationTemplateLayout.twoColumn,
            actions: [
          CPTextButton(
              title: 'Button Title 1',
              onPress: () {
                print('Button 1');
              }),
          CPTextButton(
              title: 'Button Title 2',
              onPress: () {
                print('Button 2');
              }),
        ],
            informationItems: [
          CPInformationItem(title: 'Item title 1', detail: 'detail 1'),
          CPInformationItem(title: 'Item title 2', detail: 'detail 2'),
        ]));
  }

  void openPoiTemplate() {
    FlutterCarplay.push(
        template: CPPointOfInterestTemplate(title: 'Title', poi: [
      CPPointOfInterest(
        latitude: 51.5052,
        longitude: 7.4938,
        title: 'Title',
        subtitle: 'Subtitle',
        summary: 'Summary',
        detailTitle: 'DetailTitle',
        detailSubtitle: 'detailSubtitle',
        detailSummary: 'detailSummary',
        image: 'images/logo_flutter_1080px_clr.png',
        primaryButton: CPTextButton(
            title: 'Primary',
            onPress: () {
              print('Primary button pressed');
            }),
        secondaryButton: CPTextButton(
            title: 'Secondary',
            onPress: () {
              print('Secondary button pressed');
            }),
      ),
    ]));
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
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
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
                      title: 'Blank Screen',
                      emptyViewTitleVariants: ['Blank Screen Example'],
                      emptyViewSubtitleVariants: [
                        "You've just added a blank screen to carplay from your iphone.",
                      ],
                      showsTabBadge: true,
                      systemIcon: 'airpods',
                    ),
                  ),
                  child: const Text(
                    'Add blank screen',
                    textAlign: TextAlign.center,
                  ),
                ),
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
                    'Remove last screen',
                    textAlign: TextAlign.center,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 15),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                  ),
                  onPressed: () => setBlankRootTemplate(),
                  child: const Text(
                    'Set blank rootTemplate',
                    textAlign: TextAlign.center,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 15),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                  ),
                  onPressed: () {
                    if (Platform.isIOS) {
                      setInitialCarplayRootTemplate();
                    } else if (Platform.isAndroid) {
                      setInitialAndroidAutoRootTemplate();
                    }
                  },
                  child: const Text(
                    'Set initial rootTemplate',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Center(
              child: Text(
                'Connection Status: ${connectionStatus.name}',
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
                const SizedBox(width: 15),
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
                const SizedBox(width: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 15),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                  ),
                  onPressed: () {
                    if (!Platform.isIOS) {
                      print(
                          'This example has not been yet updated for Android');
                      return;
                    }
                    FlutterCarplay.popModal();
                  },
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
                  onPressed: () {
                    if (Platform.isIOS) {
                      FlutterCarplay.pop();
                    } else if (Platform.isAndroid) {
                      FlutterAndroidAuto.pop();
                    }
                  },
                  child: const Text('Pop Screen'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 15),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                  ),
                  onPressed: () {
                    if (Platform.isIOS) {
                      FlutterCarplay.popToRoot();
                    } else if (Platform.isAndroid) {
                      FlutterAndroidAuto.popToRoot();
                    }
                  },
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
                const SizedBox(width: 20),
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
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 15),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                  ),
                  onPressed: () => openSvgExamplesTemplate(),
                  child: const Text('Open SVG\nExamples'),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 15),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
              ),
              onPressed: () {
                if (Platform.isIOS) {
                  _flutterCarplay.forceUpdateRootTemplate();
                } else if (Platform.isAndroid) {
                  _flutterAndroidAuto.forceUpdateRootTemplate();
                }
              },
              child: const Text('Force Update Carplay'),
            ),
            const SizedBox(width: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 15),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
              ),
              onPressed: () {
                if (Platform.isIOS) {
                  print(FlutterCarPlayController.templateHistory.length);
                  print(FlutterCarPlayController.templateHistory.hashCode);
                  print(FlutterCarPlayController.templateHistory);
                } else if (Platform.isAndroid) {
                  print(FlutterAndroidAutoController.templateHistory.length);
                  print(FlutterAndroidAutoController.templateHistory.hashCode);
                  print(FlutterAndroidAutoController.templateHistory);
                }
              },
              child: const Text('Load history'),
            ),
            const SizedBox(width: 50),
          ],
        ),
      ),
    );
  }
}
