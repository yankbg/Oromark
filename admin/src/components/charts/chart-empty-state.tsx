import { ChartBarSquareIcon } from "@heroicons/react/24/outline";

export function ChartEmptyState({ message }: { message: string }) {
  return (
    <div className="flex h-64 flex-col items-center justify-center gap-2 px-6 text-center">
      <ChartBarSquareIcon className="size-8 text-muted-foreground/40" />
      <p className="max-w-xs text-sm text-muted-foreground">{message}</p>
    </div>
  );
}
