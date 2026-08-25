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
} from "@/components/ui/sidebar";
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
    <Sidebar collapsible="icon">
      <SidebarHeader className="px-3 py-4">
        <Link href="/" className="flex items-center gap-2.5 px-1">
          <Image
            src="/oromark-icon.png"
            alt=""
            width={28}
            height={28}
            className="shrink-0"
          />
          <div className="flex flex-col leading-none group-data-[collapsible=icon]:hidden">
            <span className="font-display font-semibold text-sm tracking-tight text-sidebar-foreground">
              OROmark
            </span>
            <span className="text-[11px] text-sidebar-foreground/60">Admin</span>
          </div>
        </Link>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupContent>
            <SidebarMenu>
              {NAV_ITEMS.map((item) => {
                const active =
                  item.href === "/"
                    ? pathname === "/"
                    : pathname.startsWith(item.href);
                return (
                  <SidebarMenuItem key={item.href}>
                    <SidebarMenuButton asChild isActive={active} tooltip={item.label}>
                      <Link href={item.href}>
                        <item.icon />
                        <span>{item.label}</span>
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
          <SidebarMenuButton type="submit" tooltip="Sign out">
            <LogOut />
            <span>Sign out</span>
          </SidebarMenuButton>
        </form>
      </SidebarFooter>
    </Sidebar>
  );
}
