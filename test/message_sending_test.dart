import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_interview_lohit/models/chat_model.dart';

void main() {
  group('Message Sending Tests', () {
    test('Parse sent message response', () {
      final messageJson = {
        'chatId': '679bbd688c09df5b75cd1070',
        'senderId': '673d80bc2330e08c323f4393',
        'content': 'Hii',
        'messageType': 'text',
        'fileUrl': '',
        'deletedBy': [],
        'status': 'sent',
        'deliveredAt': null,
        'seenAt': null,
        'seenBy': [],
        '_id': '689809ae1c844e80ec5799aa',
        'reactions': [],
        'sentAt': '2025-08-10T02:53:34.964Z',
        'createdAt': '2025-08-10T02:53:34.965Z',
        'updatedAt': '2025-08-10T02:53:34.965Z',
        '__v': 0
      };

      final message = Message.fromJson(messageJson);

      expect(message.id, '689809ae1c844e80ec5799aa');
      expect(message.chatId, '679bbd688c09df5b75cd1070');
      expect(message.senderId, '673d80bc2330e08c323f4393');
      expect(message.content, 'Hii');
      expect(message.messageType, 'text');
      expect(message.status, 'sent');
      expect(message.isRead, false);
      expect(message.seenBy.length, 0);
      expect(message.deletedBy.length, 0);
      expect(message.reactions.length, 0);
    });

    test('Parse seen message response', () {
      final messageJson = {
        '_id': '67a492cca1755e6913738049',
        'chatId': '679bbd688c09df5b75cd1070',
        'senderId': '673d80bc2330e08c323f4393',
        'content': 'hello',
        'messageType': 'text',
        'deletedBy': [],
        'status': 'seen',
        'deliveredAt': null,
        'seenAt': '2025-04-04T06:27:54.396Z',
        'seenBy': ['673d80bc2330e08c323f4393', '673dbbf72330e08c323f4818'],
        'reactions': [],
        'sentAt': '2025-02-06T10:45:32.525Z',
        'createdAt': '2025-02-06T10:45:32.527Z',
        'updatedAt': '2025-04-04T06:27:54.397Z',
        '__v': 3
      };

      final message = Message.fromJson(messageJson);

      expect(message.id, '67a492cca1755e6913738049');
      expect(message.content, 'hello');
      expect(message.status, 'seen');
      expect(message.isRead, true);
      expect(message.seenBy.length, 2);
      expect(message.seenBy.contains('673d80bc2330e08c323f4393'), true);
      expect(message.seenBy.contains('673dbbf72330e08c323f4818'), true);
    });

    test('Create SendMessageRequest', () {
      final request = SendMessageRequest(
        chatId: 'test-chat-id',
        senderId: 'test-sender-id',
        content: 'Hello world!',
        messageType: 'text',
        fileUrl: '',
      );

      final json = request.toJson();

      expect(json['chatId'], 'test-chat-id');
      expect(json['senderId'], 'test-sender-id');
      expect(json['content'], 'Hello world!');
      expect(json['messageType'], 'text');
      expect(json['fileUrl'], '');
    });
  });
}
