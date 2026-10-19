const express = require("express");
const http = require("http");
const cors = require("cors");
const { Server } = require("socket.io");

const app = express();

app.use(cors());
app.use(express.json());

const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const rooms = new Map();

app.get("/", (req, res) => {
  res.json({
    name: "QuickDrop Signaling Server",
    version: "1.0.0",
    status: "running"
  });
});

io.on("connection", (socket) => {
  console.log(`Client connected: ${socket.id}`);

  socket.on("join-room", ({ roomId }) => {
    if (!roomId) {
      socket.emit("error-message", "Room ID is required");
      return;
    }

    let room = rooms.get(roomId);

    if (!room) {
      room = new Set();
      rooms.set(roomId, room);
    }

    if (room.size >= 2) {
      socket.emit("room-full");
      return;
    }

    room.add(socket.id);

    socket.join(roomId);
    socket.data.roomId = roomId;

    socket.emit("joined-room", {
      roomId,
      socketId: socket.id
    });

    console.log(
      `${socket.id} joined ${roomId}`
    );

    if (room.size === 2) {
      const peers = Array.from(room);

      io.to(peers[0]).emit("peer-ready", {
        initiator: true,
      });

      io.to(peers[1]).emit("peer-ready", {
        initiator: false,
      });
    }
  });

  socket.on("signal", ({ roomId, data }) => {
    if (!roomId || !data) {
      return;
    }

    socket.to(roomId).emit("signal", {
      from: socket.id,
      data
    });
  });

  socket.on("leave-room", () => {
    leaveRoom(socket);
  });

  socket.on("disconnect", () => {
    leaveRoom(socket);

    console.log(
      `Client disconnected: ${socket.id}`
    );
  });
});

function leaveRoom(socket) {
  const roomId = socket.data.roomId;

  if (!roomId) {
    return;
  }

  const room = rooms.get(roomId);

  if (!room) {
    return;
  }

  room.delete(socket.id);

  socket.to(roomId).emit("peer-left");

  if (room.size === 0) {
    rooms.delete(roomId);
  }
}

const PORT = 3000;

server.listen(PORT, "0.0.0.0", () => {
  console.log(
    `QuickDrop signaling server running on port ${PORT}`
  );
});