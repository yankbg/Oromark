"use client";

import { Area, AreaChart, CartesianGrid, XAxis, YAxis } from "recharts";
import { ChartContainer, ChartTooltip, ChartTooltipContent, type ChartConfig } from "@/components/ui/chart";
import { ChartEmptyState } from "@/components/charts/chart-empty-state";

const config: ChartConfig = {
  present: { label: "Present", color: "var(--oro-present-text)" },
  late: { label: "Late", color: "var(--oro-late-text)" },
  absent: { label: "Absent", color: "var(--oro-absent-text)" },
};

function formatDay(iso: string) {
  return new Intl.DateTimeFormat("en-GB", { day: "2-digit", month: "short" }).format(new Date(iso));
}

export function AttendanceTrendChart({
  data,
}: {
  data: { date: string; present: number; late: number; absent: number }[];
}) {
  const hasData = data.some((d) => d.present + d.late + d.absent > 0);

  if (!hasData) {
    return (
      <ChartEmptyState message="No attendance activity in this window yet. It'll appear here once a lecturer's phone syncs after class." />
    );
  }

  return (
    <ChartContainer config={config} className="h-64 w-full">
      <AreaChart data={data} margin={{ left: 0, right: 12, top: 8, bottom: 0 }}>
        <defs>
          <linearGradient id="fillPresent" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="var(--oro-present-text)" stopOpacity={0.25} />
            <stop offset="95%" stopColor="var(--oro-present-text)" stopOpacity={0.02} />
          </linearGradient>
        </defs>
        <CartesianGrid vertical={false} strokeDasharray="3 3" />
        <XAxis
          dataKey="date"
          tickFormatter={formatDay}
          tickLine={false}
          axisLine={false}
          tickMargin={8}
          minTickGap={24}
        />
        <YAxis tickLine={false} axisLine={false} tickMargin={8} allowDecimals={false} width={28} />
        <ChartTooltip
          content={<ChartTooltipContent labelFormatter={(l) => formatDay(String(l))} />}
        />
        <Area
          dataKey="present"
          type="monotone"
          stroke="var(--oro-present-text)"
          fill="url(#fillPresent)"
          strokeWidth={2}
          isAnimationActive={false}
        />
        <Area
          dataKey="late"
          type="monotone"
          stroke="var(--oro-late-text)"
          fill="none"
          strokeWidth={2}
          strokeDasharray="4 3"
          isAnimationActive={false}
        />
        <Area
          dataKey="absent"
          type="monotone"
          stroke="var(--oro-absent-text)"
          fill="none"
          strokeWidth={2}
          strokeDasharray="2 2"
          isAnimationActive={false}
        />
      </AreaChart>
    </ChartContainer>
  );
}
