# WebSockets Implementation in Soul CLI

Soul CLI provides robust support for WebSocket connections, enabling real-time, bidirectional communication between the client and server. This document explains how WebSockets are implemented and used in Soul CLI projects.

## Defining WebSockets in the API File

WebSockets are defined in your API file using the `socket` keyword. Soul CLI supports both unidirectional and bidirectional WebSocket communications. Here's an example:

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
        client:write-magnet (WriteMagnetRequest) <<>> server:write-magnet-line (WriteMagnetResponse)
    )
}
```

This definition specifies the message types that can be sent and received over the WebSocket connection. Note the different annotations:

- `>>`: Indicates a client-to-server message
- `<<`: Indicates a server-to-client message
- `<<>>`: Indicates a bidirectional message (both client-to-server and server-to-client)

## Bidirectional Communication

The bidirectional annotation (`<<>>`) is particularly useful for scenarios where you need immediate two-way communication. In the example above, `write-magnet` is defined as a bidirectional message:

```
client:write-magnet (WriteMagnetRequest) <<>> server:write-magnet-line (WriteMagnetResponse)
```

This means that:

1. The client can send a `WriteMagnetRequest` to the server.
2. The server can respond with multiple `WriteMagnetResponse` messages.
3. This allows for scenarios like streaming responses or progress updates.

## Flexible Path Structure

[Content remains the same as in the original document]

## WebSocket Handler Implementation

[Content remains the same as in the original document]

## WebSocket Logic

The business logic for handling WebSocket messages is implemented in a corresponding file within the `internal/logic/` directory. For bidirectional messages, you'll typically implement methods for both sending and receiving. For example:

```go
func (l *WsLogic) ClientWriteMagnet(req *types.WriteMagnetRequest) (resp *types.WriteMagnetResponse, err error) {
    // Handle the incoming request
    // ...
    return
}

func (l *WsLogic) ServerWriteMagnetLine(req *types.WriteMagnetRequest) {
    // Send updates to the client
    // ...
    events.Next(types.TopicServerWriteMagnetLine, resp, l.conn)
}
```

## Event System

[Content remains the same as in the original document]

## Best Practices for Using WebSockets in Soul CLI

[Content remains the same as in the original document]

## Example: Implementing a Lead Magnet Generator

Here's an example of how you might implement a lead magnet generator using bidirectional WebSocket communication:

1. In your WebSocket logic file, implement the `ClientWriteMagnet` method:

```go
func (l *WsLogic) ClientWriteMagnet(req *types.WriteMagnetRequest) (resp *types.WriteMagnetResponse, err error) {
    go l.ServerWriteMagnetLine(req)

    resp = &types.WriteMagnetResponse{
        Status: "preparing to write lead magnet...",
    }
    return
}
```

2. Implement the `ServerWriteMagnetLine` method:

```go
func (l *WsLogic) ServerWriteMagnetLine(req *types.WriteMagnetRequest) {
    // Generate lead magnet content
    err := leadmagnet.GenerateLeadMagnet(chatGPTService, params, true, func(line string) error {
        resp := &types.WriteMagnetResponse{
            Status:  "generating lead magnet...",
            Content: line,
        }
        return events.Next(types.TopicServerWriteMagnetLine, resp, l.conn)
    })

    if err != nil {
        events.Next(types.TopicServerWriteMagnetLine, fmt.Sprintf("Error: %v", err), l.conn)
    }
}
```

3. On the client side, implement logic to send the initial request and handle incoming updates.

By leveraging Soul CLI's bidirectional WebSocket implementation, you can create sophisticated real-time features that require ongoing communication between client and server, such as AI-powered content generation, real-time collaboration tools, or live data streaming.
