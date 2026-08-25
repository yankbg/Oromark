"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import {
  LayoutGrid,
  GraduationCap,
  UsersRound,
  BookOpen,
  LogOut,
} from "lucide-react";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarSeparator,
} from "@/components/ui/sidebar";
import { cn } from "@/lib/utils";
import { logout } from "@/app/(dashboard)/actions";

const NAV_ITEMS = [
  { href: "/", label: "Overview", icon: LayoutGrid },
  { href: "/students", label: "Students", icon: GraduationCap },
  { href: "/lecturers", label: "Lecturers", icon: UsersRound },
  { href: "/courses", label: "Courses", icon: BookOpen },
];

export function AppSidebar() {
  const pathname = usePathname();

  return (
    <Sidebar collapsible="icon" variant="inset">
      <SidebarHeader className="px-3.5 pt-4 pb-2">
        <Link href="/" className="flex items-center gap-2.5 px-1">
          <Image
            src="/oromark-icon.png"
            alt=""
            width={26}
            height={26}
            className="shrink-0"
          />
          <div className="flex flex-col leading-none group-data-[collapsible=icon]:hidden">
            <span className="font-display text-[15px] font-semibold tracking-tight text-sidebar-foreground">
              OROmark
            </span>
            <span className="text-[11px] text-sidebar-foreground/55">
              Attendance admin
            </span>
          </div>
        </Link>
      </SidebarHeader>

      <SidebarSeparator className="mb-2 bg-sidebar-foreground/10" />

      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupContent>
            <SidebarMenu className="gap-1">
              {NAV_ITEMS.map((item) => {
                const active =
                  item.href === "/"
                    ? pathname === "/"
                    : pathname.startsWith(item.href);
                return (
                  <SidebarMenuItem key={item.href}>
                    <SidebarMenuButton
                      asChild
                      isActive={active}
                      tooltip={item.label}
                      className={cn(
                        "h-9 rounded-lg text-sidebar-foreground/75 transition-colors",
                        "hover:bg-sidebar-accent hover:text-sidebar-foreground",
                        active &&
                          "bg-primary/90 text-white hover:bg-primary/90 hover:text-white data-active:bg-primary/90 data-active:text-white [&_svg]:text-white"
                      )}
                    >
                      <Link href={item.href}>
                        <item.icon className="size-4.5" />
                        <span className="text-[13.5px] font-medium">{item.label}</span>
                      </Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                );
              })}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter className="px-3 pb-3">
        <form action={logout}>
          <SidebarMenuButton
            type="submit"
            tooltip="Sign out"
            className="h-9 rounded-lg text-sidebar-foreground/70 hover:bg-[color-mix(in_oklch,var(--oro-error),transparent_82%)] hover:text-white"
          >
            <LogOut className="size-4.5" />
            <span className="text-[13.5px] font-medium">Sign out</span>
          </SidebarMenuButton>
        </form>
      </SidebarFooter>
    </Sidebar>
  );
}
