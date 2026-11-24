class AgoraService {
  static const String appId = '';

  Future<void> initialize() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  Future<void> joinChannel({
    required String token,
    required String channelId,
    required int uid,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  Future<void> leaveChannel() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  Future<void> muteLocalAudio(bool mute) async {}

  Future<void> muteLocalVideo(bool mute) async {}

  Future<void> dispose() async {}

  Object? get engine => null;
}
