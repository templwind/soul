export const getApiUrl = (path: string) => {
    // Remove leading slash if it exists
    const cleanPath = path.startsWith('/') ? path.substring(1) : path;
    // Use DEV to determine if we're in development
    const prefix = import.meta.env.DEV ? 'api/' : '';
    // Get the base URL
    const baseUrl = import.meta.env.DEV ? 'http://localhost:5173' : window.location.origin;
    return `${baseUrl}/${prefix}${cleanPath}`;
}; 