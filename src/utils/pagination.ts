export type MetaLike = {
  current_page?: number;
  last_page?: number;
  per_page?: number;
  total?: number;
};

export type PaginationState = {
  currentPage: number;
  lastPage: number;
  perPage: number;
  total: number;
  hasMore: boolean;
};

export function buildPagination(
  meta: MetaLike | undefined | null,
  prev: PaginationState,
  fallbackPage: number,
  dataLength: number,
): PaginationState {
  const currentPage = typeof meta?.current_page === 'number' ? meta!.current_page : (fallbackPage ?? prev.currentPage ?? 1);
  const lastPage = typeof meta?.last_page === 'number' ? meta!.last_page : (typeof meta?.current_page === 'number' ? meta!.current_page : (fallbackPage ?? prev.lastPage ?? 1));
  const perPage = typeof meta?.per_page === 'number' ? meta!.per_page : (prev.perPage ?? 20);
  const total = typeof meta?.total === 'number' ? meta!.total : (prev.total ?? (dataLength || 0));

  const hasMore = (typeof meta?.current_page === 'number' && typeof meta?.last_page === 'number')
    ? (meta!.current_page! < meta!.last_page!)
    : (dataLength >= perPage);

  return { currentPage, lastPage, perPage, total, hasMore };
}
