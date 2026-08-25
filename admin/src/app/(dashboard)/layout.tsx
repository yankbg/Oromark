import { redirect } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";
import { SidebarProvider, SidebarInset, SidebarTrigger } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/app-sidebar";
import { Separator } from "@/components/ui/separator";
import { TooltipProvider } from "@/components/ui/tooltip";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Proxy already gates every route, but Server Functions bypass proxy
  // matchers in some edge cases — re-verify here too (defense in depth).
  if (!(await isAuthenticated())) {
    redirect("/login");
  }

  return (
    <TooltipProvider delayDuration={200}>
      <SidebarProvider className="bg-[var(--oro-page-bg)]">
        <AppSidebar />
        <SidebarInset>
          <header className="flex h-14 shrink-0 items-center gap-2 border-b border-border px-5">
            <SidebarTrigger />
            <Separator orientation="vertical" className="h-5" />
            <span className="font-display text-sm font-medium text-foreground">
              OROmark Admin
            </span>
            <span className="text-sm text-muted-foreground">
              &middot; attendance records
            </span>
          </header>
          <main className="flex-1 p-6 md:p-8">
            <div className="mx-auto w-full max-w-6xl">{children}</div>
          </main>
        </SidebarInset>
      </SidebarProvider>
    </TooltipProvider>
  );
}
