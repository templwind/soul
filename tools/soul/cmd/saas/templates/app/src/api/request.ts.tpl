// api.ts

type Method = "GET" | "POST" | "PUT" | "DELETE" | "PATCH";

// Access the base URL from environment variables
const BASE_URL = import.meta.env.VITE_API_BASE_URL || "";

// The `request` function is now a private function within the module
async function request({
  method,
  url,
  data,
  config = {},
}: {
  method: Method;
  url: string;
  data?: unknown;
  config?: RequestInit;
}) {
  const headers = new Headers(config.headers || {});
  headers.set("Content-Type", "application/json");
  headers.set("Accept", "application/json");

  const finalConfig: RequestInit = {
    method: method.toUpperCase(),
    credentials: "include", // Ensure cookies are sent with requests
    headers,
    body:
      method !== "GET" && method.toString() !== "HEAD"
        ? JSON.stringify(data)
        : undefined,
    ...config,
  };

  try {
    // Prepend the base URL to the endpoint URL
    const fullUrl = `${BASE_URL}${url}`;
    const response = await fetch(fullUrl, finalConfig);

    if (!response.ok) {
      const errorResponse = await response.json();
      throw new Error(
        `HTTP error! Status: ${response.status}, Message: ${errorResponse.message}`
      );
    }
    return await response.json();
  } catch (error) {
    console.error("Fetch error:", error);
    throw error; // Re-throw to ensure errors can be handled further up the chain
  }
}

// Exporting an object with methods to interact with the API
const api = {
  get<T>(url: string, config?: RequestInit): Promise<T> {
    return request({ method: "GET", url, config });
  },
  post<T>(url: string, data?: unknown, config?: RequestInit): Promise<T> {
    return request({ method: "POST", url, data, config });
  },
  put<T>(url: string, data?: unknown, config?: RequestInit): Promise<T> {
    return request({ method: "PUT", url, data, config });
  },
  delete<T>(url: string, config?: RequestInit): Promise<T> {
    return request({ method: "DELETE", url, config });
  },
  patch<T>(url: string, data?: unknown, config?: RequestInit): Promise<T> {
    return request({ method: "PATCH", url, data, config });
  },
};

export default api;
