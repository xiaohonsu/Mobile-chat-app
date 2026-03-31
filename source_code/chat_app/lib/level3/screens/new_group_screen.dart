import 'package:flutter/material.dart';
import '../../core/models/chat_room.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../level1/services/auth_service.dart';
import '../../level1/services/chat_service.dart';
import 'chat_screen.dart';

class NewGroupScreen extends StatefulWidget {
  final UserModel currentUser;
  const NewGroupScreen({super.key, required this.currentUser});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _nameCtrl = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  final Set<String> _selectedUids = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await ChatService().getAvailableUsers();
    if (mounted) setState(() { _users = users; _loading = false; });
  }

  Future<void> _createGroup() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selectedUids.isEmpty) return;

    // Build member lists including current user
    final allIds = [widget.currentUser.uid, ..._selectedUids];
    final allNames = [
      widget.currentUser.displayName,
      ..._users
          .where((u) => _selectedUids.contains(u['uid']))
          .map((u) => u['displayName'] as String),
    ];

    final chatId = await ChatService().createEncryptedGroupChat(
      groupName: name,
      memberIds: allIds,
      memberNames: allNames,
    );

    if (!mounted) return;

    final room = ChatRoom(
      id: chatId,
      memberIds: allIds,
      memberNames: allNames,
      isGroup: true,
      groupName: name,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AdvancedChatScreen(
          chatRoom: room,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _nameCtrl.text.trim().isNotEmpty && _selectedUids.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group Chat'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Group name input
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Group Name *',
                      prefixIcon: const Icon(Icons.group),
                      hintText: 'e.g. Demo Team (required)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                // Selected count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.person_add, size: 14, color: AppTheme.level3Color),
                      const SizedBox(width: 6),
                      Text(
                        _selectedUids.isEmpty
                            ? 'Select members to add'
                            : '${_selectedUids.length} member(s) selected',
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedUids.isEmpty
                              ? Colors.grey[500]
                              : AppTheme.level3Color,
                          fontWeight: _selectedUids.isEmpty
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // User list with checkboxes
                Expanded(
                  child: _users.isEmpty
                      ? const Center(
                          child: Text('No other users found.\nAsk teammates to register!',
                              textAlign: TextAlign.center))
                      : ListView.separated(
                          itemCount: _users.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 70),
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final uid = user['uid'] as String;
                            final name = user['displayName'] as String? ?? 'User';
                            final email = user['email'] as String? ?? '';
                            final isOnline = user['isOnline'] as bool? ?? false;
                            final selected = _selectedUids.contains(uid);

                            return CheckboxListTile(
                              value: selected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedUids.add(uid);
                                  } else {
                                    _selectedUids.remove(uid);
                                  }
                                });
                              },
                              secondary: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: selected
                                        ? AppTheme.level3Color
                                        : AppTheme.primary,
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  if (isOnline)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(email,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500])),
                              activeColor: AppTheme.level3Color,
                              controlAffinity: ListTileControlAffinity.trailing,
                            );
                          },
                        ),
                ),

                // Bottom create button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: canCreate ? _createGroup : null,
                        icon: const Icon(Icons.lock),
                        label: Text(
                          _nameCtrl.text.trim().isEmpty
                              ? 'Enter a group name first'
                              : _selectedUids.isEmpty
                                  ? 'Select at least 1 member'
                                  : 'Create Encrypted Group (${_selectedUids.length + 1} members)',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.level3Color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
