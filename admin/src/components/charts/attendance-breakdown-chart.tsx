"use client";

import { Cell, Pie, PieChart } from "recharts";
import { ChartContainer, ChartTooltip, ChartTooltipContent, type ChartConfig } from "@/components/ui/chart";
import { ChartEmptyState } from "@/components/charts/chart-empty-state";

const config: ChartConfig = {
  present: { label: "Present", color: "var(--oro-present-text)" },
  late: { label: "Late", color: "var(--oro-late-text)" },
  absent: { label: "Absent", color: "var(--oro-absent-text)" },
};

export function AttendanceBreakdownChart({
  present,
  late,
  absent,
}: {
  present: number;
  late: number;
  absent: number;
}) {
  const total = present + late + absent;

  if (total === 0) {
    return <ChartEmptyState message="No attendance records synced yet." />;
  }

  const data = [
    { key: "present", value: present, fill: "var(--oro-present-text)" },
    { key: "late", value: late, fill: "var(--oro-late-text)" },
    { key: "absent", value: absent, fill: "var(--oro-absent-text)" },
  ].filter((d) => d.value > 0);

  const presentPct = Math.round((present / total) * 100);

  return (
    <div className="relative">
      <ChartContainer config={config} className="h-64 w-full">
        <PieChart>
          <ChartTooltip
            content={<ChartTooltipContent hideLabel valueFormatter={(v) => `${v} (${Math.round((v / total) * 100)}%)`} />}
          />
          <Pie
            data={data}
            dataKey="value"
            nameKey="key"
            innerRadius={62}
            outerRadius={92}
            strokeWidth={3}
            stroke="var(--card)"
            isAnimationActive={false}
          >
            {data.map((entry) => (
              <Cell key={entry.key} fill={entry.fill} />
            ))}
          </Pie>
        </PieChart>
      </ChartContainer>
      <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
        <span className="font-mono text-2xl font-semibold tabular-nums text-foreground">{presentPct}%</span>
        <span className="text-xs text-muted-foreground">present</span>
      </div>
      <div className="mt-2 flex flex-wrap items-center justify-center gap-x-4 gap-y-1">
        {(Object.keys(config) as (keyof typeof config)[]).map((key) => (
          <div key={key} className="flex items-center gap-1.5 text-xs text-muted-foreground">
            <span className="size-2 rounded-full" style={{ backgroundColor: config[key].color }} />
            {config[key].label}
          </div>
        ))}
      </div>
    </div>
  );
}
