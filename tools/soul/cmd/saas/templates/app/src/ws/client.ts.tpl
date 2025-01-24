import { v4 as uuidv4 } from "uuid"; // You need to install uuid package

export type MessageHandler = (data: any) => void;
export type EventHandler = () => void;

export class WsClient {
  private ws: WebSocket | null = null;
  private url: string;
  private reconnectInterval: number;
  private maxRetries: number;
  private retries: number = 0;
  private messageHandlers: Map<string, MessageHandler> = new Map();
  private eventHandlers: Map<string, EventHandler[]> = new Map();
  private pingInterval: number = 60000; // 60 seconds for demonstration purposes
  private pingTimeoutId: number | null = null;

  constructor(
    path: string,
    reconnectInterval: number = 1000,
    maxRetries: number = 10
  ) {
    this.url = this.getWebSocketURL(path);
    this.reconnectInterval = reconnectInterval;
    this.maxRetries = maxRetries;
    this.connect();
  }

  private getWebSocketURL(path: string): string {
    const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    const host = window.location.host;
    return `${protocol}//${host}${path}`;
  }

  private connect() {
    this.ws = new WebSocket(this.url);

    this.ws.onopen = () => {
      console.log("Connected to WebSocket");
      this.retries = 0;
      this.emitEvent("open");
      this.startPing();
    };

    this.ws.onmessage = (message: MessageEvent) => {
      this.handleMessage(message);
    };

    this.ws.onclose = (event: CloseEvent) => {
      console.log(`WebSocket closed: ${event.reason}`);
      this.emitEvent("close");
      this.stopPing();
      this.reconnect();
    };

    this.ws.onerror = (event: Event) => {
      console.error("WebSocket error:", event);
      this.emitEvent("error");
      this.ws?.close();
    };
  }

  private reconnect() {
    if (this.retries < this.maxRetries) {
      setTimeout(() => {
        console.log(`Reconnecting... (${this.retries + 1}/${this.maxRetries})`);
        this.retries++;
        this.connect();
      }, this.reconnectInterval);
    } else {
      console.error("Max retries reached. Could not reconnect to WebSocket.");
    }
  }

  private handleMessage(message: MessageEvent) {
    try {
      if (message.data.startsWith("{") || message.data.startsWith("[")) {
        const parsedData = JSON.parse(message.data);
        const topic = parsedData.topic;
        const handler = this.messageHandlers.get(topic);

        if (handler) {
          handler(parsedData.payload);
        } else {
          console.warn(`No handler found for message topic: ${topic}`);
        }
      } else if (message.data === "pong") {
        console.log("Received pong");
      } else if (message.data === "ok") {
        console.log("Received ok");
      } else {
        console.warn("Received non-JSON message:", message.data);
      }
    } catch (error) {
      console.error("Error handling message:", error);
    }
  }

  private startPing() {
    this.ping();
    this.pingTimeoutId = window.setInterval(
      () => this.ping(),
      this.pingInterval
    );
  }

  private stopPing() {
    if (this.pingTimeoutId !== null) {
      window.clearInterval(this.pingTimeoutId);
      this.pingTimeoutId = null;
    }
  }

  private ping() {
    if (this.isConnected()) {
      console.log("Sending ping");
      this.send("ping");
    }
  }

  public onMessage(topic: string, handler: MessageHandler) {
    this.messageHandlers.set(topic, handler);
  }

  public send(data: any): WsClient {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      if (typeof data !== "string") {
        if (!data.id) {
          data.id = uuidv4();
        }
        data = JSON.stringify(data);
      }
      this.ws.send(data);
    } else {
      console.error("WebSocket is not open. Unable to send message.");
    }
    return this;
  }

  public close() {
    this.ws?.close();
  }

  public isConnected(): boolean {
    return this.ws?.readyState === WebSocket.OPEN;
  }

  public onEvent(event: string, handler: EventHandler) {
    if (!this.eventHandlers.has(event)) {
      this.eventHandlers.set(event, []);
    }
    this.eventHandlers.get(event)?.push(handler);
  }

  private emitEvent(event: string) {
    const handlers = this.eventHandlers.get(event);
    if (handlers) {
      handlers.forEach((handler) => handler());
    }
  }

  public broadcast(topic: string, payload: any) {
    this.send({
      topic: "broadcast",
      id: uuidv4(),
      payload: { topic, payload },
    });
  }

  public subscribe(topic: string, handler?: MessageHandler): () => void {
    if (handler) {
      this.onMessage(topic, handler);
    }
    this.send({
      topic: "subscribe",
      id: uuidv4(),
      payload: { topic },
    });

    // Return unsubscribe function
    return () => this.unsubscribe(topic);
  }

  public unsubscribe(topic: string) {
    this.messageHandlers.delete(topic);
    this.send({
      topic: "unsubscribe",
      id: uuidv4(),
      payload: { topic },
    });
  }
}
