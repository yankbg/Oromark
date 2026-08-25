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
      <SidebarHeader className="px-4 pt-5 pb-3">
        <Link href="/" className="flex items-center gap-3 px-1">
          <Image
            src="/oromark-icon.png"
            alt=""
            width={32}
            height={32}
            className="shrink-0"
          />
          <div className="flex flex-col leading-none group-data-[collapsible=icon]:hidden">
            <span className="font-display text-lg font-semibold tracking-tight text-sidebar-foreground">
              OROmark
            </span>
            <span className="mt-0.5 text-xs text-sidebar-foreground/60">
              Attendance admin
            </span>
          </div>
        </Link>
      </SidebarHeader>

      <SidebarSeparator className="mb-3 bg-sidebar-foreground/10" />

      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupContent>
            <SidebarMenu className="gap-1.5">
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
                        "h-10 rounded-lg px-3 text-sidebar-foreground/70 transition-colors",
                        "hover:bg-sidebar-accent hover:text-sidebar-foreground",
                        active &&
                          "bg-primary text-white shadow-[0_1px_2px_0_rgb(16_24_21_/_0.08),0_6px_14px_-6px_rgb(15_110_86_/_0.45)] hover:bg-primary hover:text-white data-active:bg-primary data-active:text-white [&_svg]:text-white"
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

      <SidebarFooter className="px-3 pb-4">
        <form action={logout}>
          <SidebarMenuButton
            type="submit"
            tooltip="Sign out"
            className="h-10 rounded-lg px-3 text-sidebar-foreground/65 hover:bg-[color-mix(in_oklch,var(--oro-error),transparent_82%)] hover:text-white"
          >
            <ArrowRightStartOnRectangleIcon className="size-5" />
            <span className="text-sm font-medium">Sign out</span>
          </SidebarMenuButton>
        </form>
      </SidebarFooter>
    </Sidebar>
  );
}
