import { v4 as uuidv4 } from "uuid"; // You need to install uuid package

export type MessageHandler = (data: any) => void;
export type EventHandler = () => void;

export class WsClient {
  private ws: WebSocket | null = null;
  private url: string;
  private reconnectInterval: number;
  private retries: number = 0;
  private messageHandlers: Map<string, MessageHandler> = new Map();
  private eventHandlers: Map<string, EventHandler[]> = new Map();
  private pingInterval: number = 60000; // 60 seconds
  private pingTimeoutId: number | null = null;
  private debug: boolean = false;

  constructor(
    path: string,
    reconnectInterval: number = 1000,
    debug: boolean = false
  ) {
    this.url = this.getWebSocketURL(path);
    this.reconnectInterval = reconnectInterval;
    this.debug = debug;
    this.connect();
  }

  private getWebSocketURL(path: string): string {
    const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    const host = window.location.host;
    return `${protocol}//${host}${path}`;
  }

  private log(...args: any[]) {
    if (this.debug) {
      console.log('[WsClient]', ...args);
    }
  }

  private warn(...args: any[]) {
    if (this.debug) {
      console.warn('[WsClient]', ...args);
    }
  }

  private error(...args: any[]) {
    if (this.debug) {
      console.error('[WsClient]', ...args);
    }
  }

  private connect() {
    this.ws = new WebSocket(this.url);

    this.ws.onopen = () => {
      this.log("Connected to WebSocket");
      this.retries = 0;
      this.emitEvent("open");
      this.startPing();
    };

    this.ws.onmessage = (message: MessageEvent) => {
      this.handleMessage(message);
    };

    this.ws.onclose = (event: CloseEvent) => {
      this.log(`WebSocket closed: ${event.reason}`);
      this.emitEvent("close");
      this.stopPing();
      this.reconnect();
    };

    this.ws.onerror = (event: Event) => {
      this.error("WebSocket error:", event);
      this.ws?.close();
    };
  }

  private reconnect() {
    setTimeout(() => {
      this.log(`Reconnecting... (attempt ${this.retries + 1})`);
      this.retries++;
      this.connect();
    }, this.reconnectInterval);
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
          this.warn(`No handler found for message topic: ${topic}`);
        }
      } else if (message.data === "pong") {
        this.log("Received pong");
      } else if (message.data === "ok") {
        this.log("Received ok");
      } else {
        this.warn("Received non-JSON message:", message.data);
      }
    } catch (error) {
      this.error("Error handling message:", error);
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
      this.log("Sending ping");
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
      this.error("WebSocket is not open. Unable to send message.");
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

  public setDebug(enabled: boolean) {
    this.debug = enabled;
  }
}
