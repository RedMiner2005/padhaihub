import 'package:flow_builder/flow_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as ui;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:padhaihub/app/app.dart';
import 'package:padhaihub/chat/chat.dart';
import 'package:padhaihub/chat/cubit/chat_cubit.dart';
import 'package:padhaihub/src/src.dart';
import 'package:stream_transform/stream_transform.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen._({super.key, required this.room});

  final types.Room room;

  static Page<void> page(types.Room room) =>
      MaterialPage<void>(child: ChatScreen._(room: room,));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
          final cubit = ChatCubit(context.read<AppBloc>().storageRepository, room);
          cubit.listenAuth();
          return cubit;
        },
      child: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          if (state.authUser == null) {
            return const Scaffold(
              body: LoadingWidget(),
            );
          }
          if (state.room?.id == "") {
            FirebaseChatCore.instance.createRoom(
                state.room!.users.first,
              metadata: Map.fromIterables(
                  state.room!.users.map((e) => e.id),
                  state.room!.users.map((e) => DateTime.timestamp().millisecondsSinceEpoch),
              )
            ).then(
                    (room) {
                  context.read<ChatCubit>().updateRoom(room);
                  // TODO: Doesn't update the main navdata, temporary fix above
                  // context.flow<NavData>().complete(
                  //         (navData) => navData.copyWith(room: room)
                  // );
                }
            );
            return const Scaffold(
              body: LoadingWidget(),
            );
          }
          // state.room!.metadata?[state.authUser!.id] = DateTime.timestamp().millisecondsSinceEpoch;
          return StreamBuilder<List<types.Message>>(
              initialData: [],
              stream: FirebaseChatCore.instance.messages(state.room!),
              builder: (context, snapshot) {
                List<types.Message> messages;
                FirebaseChatCore.instance.seeAll(state.authUser!, state.room!);
                FirebaseChatCore.instance.getLiveMetadata(state.room!.id).listen(
                  (event) {
                    context.read<ChatCubit>().updateMetadata(event);
                  }
                );
                if (state.room != null) {
                  types.User currUser = state.authUser!;
                  types.User otherUser = state.room!.users.where((element) => element.id != currUser.id).first;
                  messages = snapshot.data?.map<types.Message>((e) => e).map((message) => message.copyWith(
                      showStatus: message.author.id == currUser.id,
                      status: ((message.updatedAt ?? 0) > (state.room!.metadata?[otherUser.id] ?? -1)) ? types.Status.delivered : types.Status.seen
                  )).toList() ?? [];
                } else {
                  messages = snapshot.data?.map<types.Message>((e) => e).map((message) => message.copyWith(
                      showStatus: false
                  )).toList() ?? [];
                }
                return Scaffold(
                    appBar: AppBar(
                      title: Text(state.room!.users.where((element) => element.id != state.authUser!.id).first.firstName!),
                    ),
                    body: CustomChat(
                      messages: messages,
                      onSendPressed: context.read<ChatCubit>().onSendPressed,
                      onAttachmentPressed: context.read<ChatCubit>().onAttachmentPressed,
                      onMessageTap: context.read<ChatCubit>().onMessageTap,
                      onMessageLongPress: context.read<ChatCubit>().onMessageLongPress,
                      onMessageDoubleTap: context.read<ChatCubit>().onMessageDoubleTap,
                      user: state.authUser!,
                      isLoading: state.isLoading,
                    )
                );
              }
          );
        },
      ),
    );
  }
}

