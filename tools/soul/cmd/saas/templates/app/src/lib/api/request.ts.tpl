// api.ts
import { getApiUrl } from "$lib/utils";

// Define the method type
type Method = "GET" | "POST" | "PUT" | "DELETE" | "PATCH";

// The `request` function is now a private function within the module
async function request({
  method,
  url,
  data,
  config = {},
  customFetch,
}: {
  method: Method;
  url: string;
  data?: unknown;
  config?: RequestInit;
  customFetch?: typeof fetch;
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
    const fullUrl = getApiUrl(url);
    // Use customFetch if provided, otherwise fall back to global fetch
    const fetchFunc = customFetch || fetch;
    const response = await fetchFunc(fullUrl, finalConfig);

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
  get<T>(url: string, config?: RequestInit, customFetch?: typeof fetch): Promise<T> {
    return request({ method: "GET", url, config, customFetch });
  },
  post<T>(url: string, data?: unknown, config?: RequestInit, customFetch?: typeof fetch): Promise<T> {
    return request({ method: "POST", url, data, config, customFetch });
  },
  put<T>(url: string, data?: unknown, config?: RequestInit, customFetch?: typeof fetch): Promise<T> {
    return request({ method: "PUT", url, data, config, customFetch });
  },
  delete<T>(url: string, data?: unknown, config?: RequestInit, customFetch?: typeof fetch): Promise<T> {
    return request({ method: "DELETE", url, data, config, customFetch });
  },
  patch<T>(url: string, data?: unknown, config?: RequestInit, customFetch?: typeof fetch): Promise<T> {
    return request({ method: "PATCH", url, data, config, customFetch });
  },
};

export default api;
