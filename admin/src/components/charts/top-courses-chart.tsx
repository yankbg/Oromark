"use client";

import { Bar, BarChart, CartesianGrid, Cell, XAxis, YAxis } from "recharts";
import { ChartContainer, ChartTooltip, ChartTooltipContent, type ChartConfig } from "@/components/ui/chart";
import { ChartEmptyState } from "@/components/charts/chart-empty-state";

const config: ChartConfig = {
  avgAttendance: { label: "Avg. attendance", color: "var(--oro-primary)" },
};

export function TopCoursesChart({
  courses,
}: {
  courses: { courseCode: string; courseName: string; avgAttendance: number; enrolled: number }[];
}) {
  if (courses.length === 0 || courses.every((c) => c.avgAttendance === 0)) {
    return (
      <ChartEmptyState message="No course attendance averages yet — they fill in once sessions have been run and synced." />
    );
  }

  const data = [...courses].reverse(); // highest at the top of a horizontal bar chart

  return (
    <ChartContainer config={config} className="h-64 w-full">
      <BarChart data={data} layout="vertical" margin={{ left: 8, right: 24, top: 4, bottom: 4 }}>
        <CartesianGrid horizontal={false} strokeDasharray="3 3" />
        <XAxis type="number" dataKey="avgAttendance" tickLine={false} axisLine={false} unit="%" domain={[0, 100]} />
        <YAxis
          type="category"
          dataKey="courseCode"
          tickLine={false}
          axisLine={false}
          width={72}
          tick={{ fontSize: 12 }}
        />
        <ChartTooltip
          content={
            <ChartTooltipContent
              hideLabel
              valueFormatter={(v) => `${v}%`}
            />
          }
        />
        <Bar dataKey="avgAttendance" radius={[0, 6, 6, 0]} maxBarSize={22}>
          {data.map((entry, i) => (
            <Cell key={entry.courseCode} fill="var(--oro-primary)" fillOpacity={0.55 + (i / data.length) * 0.45} />
          ))}
        </Bar>
      </BarChart>
    </ChartContainer>
  );
}
