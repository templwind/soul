import { writable, get } from 'svelte/store';
import { WsClient } from '../../ws/client';
import type { MessageHandler } from '../../ws/client';
import { PUBLIC_WS_PATH, PUBLIC_RECONNECT_INTERVAL } from '$env/static/public';
import { browser } from '$app/environment';

class SocketStore {
    private static instance: SocketStore | null = null;
    private wsClient: WsClient | null = null;
    public connected = writable(false);
    public debug = writable(false);

    private constructor() { }

    public static connect(path: string, reconnectInterval: number = 1000): void {
        if (SocketStore.instance === null) {
            SocketStore.instance = new SocketStore();
        }
        SocketStore.instance.wsClient = new WsClient(path, reconnectInterval, get(SocketStore.instance.debug));
        SocketStore.instance.wsClient.onEvent('open', () => SocketStore.instance!.connected.set(true));
        SocketStore.instance.wsClient.onEvent('close', () => SocketStore.instance!.connected.set(false));
    }

    public static getInstance(): SocketStore | null {
        if (!SocketStore.instance || !SocketStore.instance.wsClient) {
            // throw new Error('SocketStore must be initialized before getting an instance');
            return null;
        }
        return SocketStore.instance;
    }

    public socket = {
        subscribe: (topic: string, handler: MessageHandler) => this.wsClient!.subscribe(topic, handler),
        unsubscribe: (topic: string) => this.wsClient!.unsubscribe(topic),
        broadcast: (topic: string, payload: any) => this.wsClient!.broadcast(topic, payload),
        send: (data: any) => this.wsClient!.send(data),
        close: () => this.wsClient!.close(),
        isConnected: () => this.wsClient!.isConnected(),
        onMessage: (topic: string, handler: MessageHandler) => this.wsClient!.onMessage(topic, handler),
    };
}

// Only connect to the socket if we're in the browser
if (browser) {
    SocketStore.connect(PUBLIC_WS_PATH, Number(PUBLIC_RECONNECT_INTERVAL));
}

export const getSocket = () => SocketStore.getInstance();
export const connected = SocketStore.getInstance()?.connected;
export const socket = getSocket()?.socket;
