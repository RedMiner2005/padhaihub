import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:padhaihub/app/app.dart';
import 'package:padhaihub/chat/chat.dart';
import 'package:padhaihub/config/config.dart';
import 'package:padhaihub/file_share/file_share.dart';
import 'package:padhaihub/home/home.dart';
import 'package:padhaihub/landing/landing.dart';

List<Page<dynamic>> onGenerateAppViewPages(
    NavData navData,
    List<Page<dynamic>> pages,
    ) {
  if (kDebugMode)
    print("Entered App View Page Generator");
  switch (navData.appStatus) {
    case AppStatus.authenticated:
      return [
        TabbedHomePage.page(),
        if(navData.room != null && navData.room?.id == PUBLIC_ROOM_ID) FileListPage.page(navData.room!),
        if(navData.room != null && navData.room?.id != PUBLIC_ROOM_ID) ChatScreen.page(navData.room!),
      ];
    case AppStatus.unauthenticated:
      return [LandingPage.page()];
    default:
      return [LoadingPage.page()];
  }
}

class NavData {
  const NavData({this.appStatus, this.user, this.homeStatus, this.room});

  final AppStatus? appStatus;
  final types.User? user;
  final HomeStatus? homeStatus;
  final types.Room? room;

  NavData copyWith({AppStatus? appStatus, types.User? user, HomeStatus? homeStatus, types.Room? room}) {
    return NavData(
      appStatus: appStatus ?? this.appStatus,
      user: user ?? this.user,
      homeStatus: homeStatus ?? this.homeStatus,
      room: room ?? this.room,
    );
  }
}
