import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageScreen extends StatefulWidget {
  final String driverId;

  const MessageScreen({super.key, required this.driverId});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _client = Supabase.instance.client;

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(dynamic value) {
    final d = _parseDate(value);
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd $hh:$min';
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _client.from('messages').update({'is_read': true}).eq('id', id);
    } catch (e) {
      debugPrint('[Messages] mark read failed: $e');
    }
  }

  void _showMessageDetails(Map<String, dynamic> msg) {
    final subject = msg['subject']?.toString() ?? 'No subject';
    final sender = msg['sender_name']?.toString() ?? 'Management';
    final body = msg['body']?.toString() ?? '';
    final attachmentUrl = msg['attachment_url']?.toString();
    final createdAt = _formatDate(msg['created_at']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('From: $sender'),
                const SizedBox(height: 4),
                Text('Time: $createdAt'),
                const SizedBox(height: 16),
                Text(body),
                const SizedBox(height: 16),
                if (attachmentUrl != null && attachmentUrl.isNotEmpty) ...[
                  const Text(
                    'Attachment',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      attachmentUrl,
                      errorBuilder: (_, __, ___) {
                        return Text(attachmentUrl);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    final id = msg['id']?.toString();
    if (id != null && (msg['is_read'] != true)) {
      _markAsRead(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages'), centerTitle: true),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _client.from('messages').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allMessages = snapshot.data ?? [];

          final messages =
              allMessages
                  .where(
                    (m) =>
                        m['recipient_driver_id']?.toString() == widget.driverId,
                  )
                  .toList()
                ..sort((a, b) {
                  final da = _parseDate(a['created_at']);
                  final db = _parseDate(b['created_at']);
                  return db.compareTo(da);
                });

          if (messages.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final msg = messages[index];
              final subject = msg['subject']?.toString() ?? 'No subject';
              final sender = msg['sender_name']?.toString() ?? 'Management';
              final body = msg['body']?.toString() ?? '';
              final isRead = msg['is_read'] == true;
              final time = _formatDate(msg['created_at']);

              return Card(
                child: ListTile(
                  leading: Icon(
                    isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                    color: isRead ? Colors.grey : Colors.blue,
                  ),
                  title: Text(
                    subject,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '$sender\n$time\n${body.length > 60 ? body.substring(0, 60) + '...' : body}',
                  ),
                  isThreeLine: true,
                  onTap: () => _showMessageDetails(msg),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
