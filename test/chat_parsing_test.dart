import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_interview_lohit/models/chat_model.dart';
import 'package:flutter_interview_lohit/utils/helpers.dart';

void main() {
  group('Chat Model Tests', () {
    test('should parse chat data correctly', () {
      final chatData = {
        'id': '123',
        'chatId': '123',
        'participantId': '456',
        'participantName': 'John Doe',
        'participantImage': 'profile/john.jpg',
        'lastMessage': 'Hello there!',
        'lastMessageTime': '2025-01-15T10:30:00Z',
        'unreadCount': 2,
        'isGroupChat': false,
        'participants': [
          {
            '_id': '456',
            'name': 'John Doe',
            'profile': 'profile/john.jpg'
          }
        ]
      };

      final chat = Chat.fromJson(chatData);

      expect(chat.id, '123');
      expect(chat.chatId, '123');
      expect(chat.participantId, '456');
      expect(chat.participantName, 'John Doe');
      expect(chat.participantImage, 'profile/john.jpg');
      expect(chat.lastMessage, 'Hello there!');
      expect(chat.unreadCount, 2);
      expect(chat.isGroupChat, false);
    });

    test('should handle missing participant data gracefully', () {
      final chatData = {
        'id': '123',
        'chatId': '123',
        'lastMessage': 'Hello there!',
        'lastMessageTime': '2025-01-15T10:30:00Z',
        'unreadCount': 0,
        'isGroupChat': false,
        'participants': []
      };

      final chat = Chat.fromJson(chatData);

      expect(chat.id, '123');
      expect(chat.participantId, '');
      expect(chat.participantName, 'Unknown User');
      expect(chat.participantImage, null);
    });

    test('should handle malformed participants data', () {
      final chatData = {
        'id': '123',
        'chatId': '123',
        'lastMessage': 'Hello there!',
        'lastMessageTime': '2025-01-15T10:30:00Z',
        'unreadCount': 0,
        'isGroupChat': false,
        'participants': 'invalid_data'
      };

      final chat = Chat.fromJson(chatData);

      expect(chat.id, '123');
      expect(chat.participantId, '');
      expect(chat.participantName, 'Unknown User');
      expect(chat.participantImage, null);
    });
  });

  group('Helpers Tests', () {
    test('should construct full image URL from relative path', () {
      final relativePath = 'vendor/Timepiece store logo with name AV.png';
      final fullUrl = Helpers.getProfileImageUrl(relativePath);
      
      expect(fullUrl, 'http://45.129.87.38:6065/vendor/Timepiece store logo with name AV.png');
    });

    test('should handle paths with leading slash', () {
      final relativePath = '/vendor/logo.png';
      final fullUrl = Helpers.getProfileImageUrl(relativePath);
      
      expect(fullUrl, 'http://45.129.87.38:6065/vendor/logo.png');
    });

    test('should return full URLs as is', () {
      final fullUrl = 'https://example.com/image.jpg';
      final result = Helpers.getProfileImageUrl(fullUrl);
      
      expect(result, fullUrl);
    });

    test('should return null for empty or null paths', () {
      expect(Helpers.getProfileImageUrl(null), null);
      expect(Helpers.getProfileImageUrl(''), null);
    });
  });
}
