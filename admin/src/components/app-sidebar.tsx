"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import {
  Squares2X2Icon,
  AcademicCapIcon,
  UserGroupIcon,
  BookOpenIcon,
  ArrowRightStartOnRectangleIcon,
} from "@heroicons/react/24/outline";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarSeparator,
} from "@/components/ui/sidebar";
import { cn } from "@/lib/utils";
import { logout } from "@/app/(dashboard)/actions";

const NAV_ITEMS = [
  { href: "/", label: "Overview", icon: Squares2X2Icon },
  { href: "/students", label: "Students", icon: AcademicCapIcon },
  { href: "/lecturers", label: "Lecturers", icon: UserGroupIcon },
  { href: "/courses", label: "Courses", icon: BookOpenIcon },
];

export function AppSidebar() {
  const pathname = usePathname();

  return (
    <Sidebar collapsible="icon" variant="inset">
      <SidebarHeader className="px-4 pt-5 pb-3 group-data-[collapsible=icon]:px-2">
        <Link
          href="/"
          className="flex items-center gap-3 px-1 group-data-[collapsible=icon]:justify-center group-data-[collapsible=icon]:px-0"
        >
          <div className="flex size-9 shrink-0 items-center justify-center rounded-xl bg-primary/10">
            <Image
              src="/oromark-icon.png"
              alt=""
              width={22}
              height={22}
              className="shrink-0"
            />
          </div>
          <div className="flex flex-col leading-none group-data-[collapsible=icon]:hidden">
            <span className="font-display text-lg font-semibold tracking-tight text-sidebar-foreground">
              OROmark
            </span>
            <span className="mt-0.5 text-xs text-sidebar-foreground/55">
              Attendance admin
            </span>
          </div>
        </Link>
      </SidebarHeader>

      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Menu</SidebarGroupLabel>
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
                        "h-10 rounded-lg px-3 text-sidebar-foreground/65 transition-colors",
                        "hover:bg-sidebar-accent hover:text-sidebar-foreground",
                        active &&
                          "bg-primary/10 text-primary hover:bg-primary/10 hover:text-primary data-active:bg-primary/10 data-active:text-primary [&_svg]:text-primary"
                      )}
                    >
                      <Link href={item.href}>
                        <item.icon className="size-5" />
                        <span className="text-sm font-medium">{item.label}</span>
                      </Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                );
              })}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarSeparator className="mb-2 bg-sidebar-border" />

      <SidebarFooter className="px-3 pb-4 group-data-[collapsible=icon]:px-2">
        <form action={logout}>
          <SidebarMenuButton
            type="submit"
            tooltip="Sign out"
            className="h-10 rounded-lg px-3 text-sidebar-foreground/60 group-data-[collapsible=icon]:mx-auto hover:bg-[color-mix(in_oklch,var(--oro-error),transparent_90%)] hover:text-[var(--oro-error)]"
          >
            <ArrowRightStartOnRectangleIcon className="size-5" />
            <span className="text-sm font-medium">Sign out</span>
          </SidebarMenuButton>
        </form>
      </SidebarFooter>
    </Sidebar>
  );
}
