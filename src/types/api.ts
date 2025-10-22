import { Reflection } from ".";
// types/api.ts
export interface APIResponse<T> {
    success: boolean;
    data: T;
    message?: string;
    errors?: Record<string, string[]>;
}

export interface DailyVersesResponse extends APIResponse<Verse[]> {
    date: string;
}

// Based on VerseResource.php response structure
export interface Verse {
    id: string;
    created_at: string;
    updated_at: string;
    reference: string;
    context_reference?: string | null;
    context_text?: string | null;
    date: string;
    text: string;
    votes: number;
    translation: string;
    theme_id: number | null;
    likes: number;
    shares: number;
    book?: string | null;
    chapter?: number | null;
    verse?: number | null;
    is_trending: boolean;
    is_active: boolean;
    is_featured: boolean;
    isLiked?: boolean; // From auth user interaction check
    isBookmarked?: boolean; // From auth user bookmark check
    reflections?: Reflection[];
}