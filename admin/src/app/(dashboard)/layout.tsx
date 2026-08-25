import { redirect } from "next/navigation";
import { Search } from "lucide-react";
import { isAuthenticated } from "@/lib/auth";
import { SidebarProvider, SidebarInset, SidebarTrigger } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/app-sidebar";
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
          <header className="flex h-16 shrink-0 items-center gap-4 px-6">
            <SidebarTrigger className="size-8" />
            <div className="relative w-full max-w-sm">
              <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
              <input
                type="search"
                placeholder="Search students, lecturers, courses…"
                className="h-9 w-full rounded-full border-none bg-muted pr-4 pl-9 text-sm text-foreground placeholder:text-muted-foreground focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
              />
            </div>
            <div className="ml-auto flex items-center gap-2">
              <span className="font-display text-sm font-medium text-foreground">
                OROmark Admin
              </span>
            </div>
          </header>
          <main className="flex-1 px-6 pb-8 md:px-8">
            <div className="w-full">{children}</div>
          </main>
        </SidebarInset>
      </SidebarProvider>
    </TooltipProvider>
  );
}
