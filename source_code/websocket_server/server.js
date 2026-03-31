/**
 * WebSocket Server — Flutter Chat App Level 2
 *
 * Events (client → server):
 *   { type: 'join_room',    chatRoomId }
 *   { type: 'leave_room',   chatRoomId }
 *   { type: 'typing_start', chatRoomId }
 *   { type: 'typing_stop',  chatRoomId }
 *   { type: 'seen',         chatRoomId, messageId }
 *
 * Events (server → client):
 *   { type: 'user_online',   userId }
 *   { type: 'user_offline',  userId }
 *   { type: 'typing_start',  chatRoomId, userId }
 *   { type: 'typing_stop',   chatRoomId, userId }
 *   { type: 'seen',          chatRoomId, messageId, userId }
 *
 * Deploy: Railway / Render / Fly.io
 *   Set PORT env var (default 8080).
 *   wss://your-app.railway.app
 */

const { WebSocketServer, WebSocket } = require('ws');

const PORT = process.env.PORT || 8080;
const wss = new WebSocketServer({ port: PORT });

// userId → WebSocket
const clients = new Map();
// chatRoomId → Set<userId>
const rooms = new Map();

wss.on('connection', (ws, req) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const userId = url.searchParams.get('userId');

  if (!userId) {
    ws.close(1008, 'Missing userId');
    return;
  }

  // Register client
  clients.set(userId, ws);
  console.log(`[+] Connected: ${userId} (total: ${clients.size})`);

  // Broadcast presence to everyone
  broadcast(null, { type: 'user_online', userId }, userId);

  ws.on('message', (raw) => {
    let event;
    try {
      event = JSON.parse(raw.toString());
    } catch {
      return;
    }

    const { type, chatRoomId, messageId } = event;

    switch (type) {
      case 'join_room':
        if (!chatRoomId) break;
        if (!rooms.has(chatRoomId)) rooms.set(chatRoomId, new Set());
        rooms.get(chatRoomId).add(userId);
        console.log(`  [room] ${userId} joined ${chatRoomId}`);
        break;

      case 'leave_room':
        if (!chatRoomId) break;
        rooms.get(chatRoomId)?.delete(userId);
        console.log(`  [room] ${userId} left ${chatRoomId}`);
        break;

      case 'typing_start':
        if (!chatRoomId) break;
        broadcastToRoom(chatRoomId, { type: 'typing_start', chatRoomId, userId }, userId);
        break;

      case 'typing_stop':
        if (!chatRoomId) break;
        broadcastToRoom(chatRoomId, { type: 'typing_stop', chatRoomId, userId }, userId);
        break;

      case 'seen':
        if (!chatRoomId || !messageId) break;
        broadcastToRoom(chatRoomId, { type: 'seen', chatRoomId, messageId, userId }, userId);
        break;

      default:
        console.warn(`  [?] Unknown event type: ${type}`);
    }
  });

  ws.on('close', () => {
    clients.delete(userId);
    // Remove from all rooms
    for (const [, members] of rooms) members.delete(userId);
    console.log(`[-] Disconnected: ${userId} (total: ${clients.size})`);
    broadcast(null, { type: 'user_offline', userId }, userId);
  });

  ws.on('error', (err) => {
    console.error(`[!] Error for ${userId}:`, err.message);
  });
});

/** Send to all members of a room except the sender. */
function broadcastToRoom(chatRoomId, payload, exceptUserId) {
  const members = rooms.get(chatRoomId);
  if (!members) return;
  const msg = JSON.stringify(payload);
  for (const memberId of members) {
    if (memberId === exceptUserId) continue;
    const ws = clients.get(memberId);
    if (ws?.readyState === WebSocket.OPEN) ws.send(msg);
  }
}

/** Send to all connected clients except the sender. */
function broadcast(chatRoomId, payload, exceptUserId) {
  const msg = JSON.stringify(payload);
  for (const [uid, ws] of clients) {
    if (uid === exceptUserId) continue;
    if (ws.readyState === WebSocket.OPEN) ws.send(msg);
  }
}

console.log(`WebSocket server listening on ws://localhost:${PORT}`);
console.log('Events: join_room, leave_room, typing_start, typing_stop, seen');
