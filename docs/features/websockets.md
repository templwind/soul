# WebSockets Implementation in Soul CLI

Soul CLI provides robust support for WebSocket connections, enabling real-time, bidirectional communication between the client and server. This document explains how WebSockets are implemented and used in Soul CLI projects.

## Defining WebSockets in the API File

WebSockets are defined in your API file using the `socket` keyword. Here's an example:

```
@server (
    group:      app/dashboard
    prefix:     app
)
service YourSaaS {
    @handler ws
    get socket /ws (
        client:stats (StatsRequest) >> (StatsResponse)
        server:stats << (StatsResponse)
        client:create-chat-room (CreateChatRoomRequest) >> (ChatRoom)
        client:list-chat-messages (ListChatMessagesRequest) >> (ListChatMessagesResponse)
        server:chat-messages << (ListChatMessagesResponse)
        client:send-chat-message (ChatMessage) >> ([]ChatMessage)
        server:chat-message << ([]ChatMessage)
    )
}
```

This definition specifies the message types that can be sent and received over the WebSocket connection.

## Flexible Path Structure

It's important to note that the path structure in your project is flexible and determined by how you define it in your API file. In the example above:

- The `group: app/dashboard` directive would create a path structure like `internal/handler/app/dashboard/` and `internal/logic/app/dashboard/`.
- The `prefix: app` directive adds an "/app" prefix to the route.

However, you have the freedom to structure your paths as needed. For example:

```
@server (
    group:      websockets
    prefix:     api
)
service YourSaaS {
    @handler realtime
    get socket /realtime (
        // WebSocket definitions
    )
}
```

This would result in a different path structure, like `internal/handler/websockets/` and `internal/logic/websockets/`, with a route prefix of "/api".

## WebSocket Handler Implementation

Soul CLI automatically generates a WebSocket handler based on your API definition. The location of this handler corresponds to the group and handler name you specify in your API file. Key features of this handler include:

1. **Connection Upgrade**: The handler upgrades the HTTP connection to a WebSocket connection.
2. **Connection Management**: It uses a `ConnectionManager` to manage WebSocket connections.
3. **Message Handling**: It processes incoming messages and routes them to the appropriate logic based on the message topic.
4. **Event Subscription**: The handler subscribes to server-initiated events and sends them to the client.
5. **Ping/Pong**: It handles WebSocket ping/pong for connection health checks.

## WebSocket Logic

The business logic for handling WebSocket messages is implemented in a corresponding file within the `internal/logic/` directory. The exact path will match the group structure defined in your API file. This file contains methods corresponding to each client message type defined in the API file. Developers should implement their custom logic in these methods.

## Event System

Soul CLI includes a powerful event system (typically in `internal/events/events.go`) that facilitates server-initiated messages and pub/sub functionality. Key features include:

1. **Topic-based Pub/Sub**: Messages are published and subscribed to specific topics.
2. **Asynchronous Processing**: Event handlers are executed asynchronously.
3. **Timeout Handling**: Event processing has a built-in timeout to prevent blocking.
4. **ReplaySubject**: Caches recent events and re-emits them to new subscribers.

## Best Practices for Using WebSockets in Soul CLI

1. **Implement Custom Logic**: Add your business logic in the corresponding methods in your WebSocket logic file.
2. **Use Server-Initiated Events**: Utilize the `events.Next()` function to send server-initiated messages.
3. **Handle Errors**: Implement proper error handling in your WebSocket logic methods.
4. **Manage Connection State**: Use the `ConnectionManager` to track and manage active connections.
5. **Implement Client-Side Reconnection**: As the server doesn't handle reconnection, implement this on the client side.

## Example: Implementing Chat Functionality

Here's a basic example of how you might implement a chat room feature:

1. In your WebSocket logic file, implement the `ClientCreateChatRoom` method:

```go
func (l *WsLogic) ClientCreateChatRoom(req *types.CreateChatRoomRequest) (resp *types.ChatRoom, err error) {
    // Create a new chat room
    room := &types.ChatRoom{
        Id: uuid.New().String(),
        UserId: req.UserId,
        Messages: []types.ChatMessage{},
    }
    // Save the room to your database
    // ...
    return room, nil
}
```

2. Implement the `ClientSendChatMessage` method:

```go
func (l *WsLogic) ClientSendChatMessage(req *types.ChatMessage) (resp []types.ChatMessage, err error) {
    // Save the message to your database
    // ...
    // Broadcast the message to all users in the room
    ServerChatMessage([]types.ChatMessage{*req})
    return []types.ChatMessage{*req}, nil
}
```

3. On the client side, implement logic to create a room, send messages, and handle incoming messages.

By leveraging Soul CLI's WebSocket implementation, you can create real-time, interactive features in your application with ease, while maintaining the flexibility to structure your project as needed.
