import { toZonedTime, format as tzFormat } from 'date-fns-tz';

export function formatRelativeTime(date: Date): string {
    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (diffInSeconds < 5) return 'just now';
    if (diffInSeconds < 60) return `${diffInSeconds} seconds ago`;

    const diffInMinutes = Math.floor(diffInSeconds / 60);
    if (diffInMinutes < 60) return `${diffInMinutes} minute${diffInMinutes === 1 ? '' : 's'} ago`;

    const diffInHours = Math.floor(diffInMinutes / 60);
    if (diffInHours < 24) return `${diffInHours} hour${diffInHours === 1 ? '' : 's'} ago`;

    const diffInDays = Math.floor(diffInHours / 24);
    if (diffInDays < 7) return `${diffInDays} day${diffInDays === 1 ? '' : 's'} ago`;

    return date.toLocaleDateString();
}


export function formatDateCustom(date: Date, format: string): string {
    const map: { [key: string]: string } = {
        'Y': date.getFullYear().toString(),
        'm': ('0' + (date.getMonth() + 1)).slice(-2),
        'd': ('0' + date.getDate()).slice(-2),
        'H': ('0' + date.getHours()).slice(-2),
        'i': ('0' + date.getMinutes()).slice(-2),
        's': ('0' + date.getSeconds()).slice(-2),
        'a': date.getHours() < 12 ? 'am' : 'pm',
        'A': date.getHours() < 12 ? 'AM' : 'PM',
    };

    return format.replace(/Y|m|d|H|i|s|a|A/g, (matched) => map[matched]);
}

export function formatDate(
    date: Date | string | undefined,
    formatStr: string,
    timeZone?: string
): string {
    // Convert the input to a Date object if needed.
    if (typeof date === 'string') {
        date = new Date(date);
    } else if (date === undefined) {
        date = new Date();
    }

    // Use the browser's timezone if none provided.
    if (!timeZone) {
        timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    }

    // Convert the date from UTC to the target time zone.
    const zonedDate = toZonedTime(date, timeZone);

    // Format the date in the target time zone.
    return tzFormat(zonedDate, formatStr, { timeZone });
}

