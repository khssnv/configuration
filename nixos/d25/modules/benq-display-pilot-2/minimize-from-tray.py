import sys

import dbus
from dbus.exceptions import DBusException

PROPERTIES = "org.freedesktop.DBus.Properties"
WATCHER = "org.kde.StatusNotifierWatcher"
WATCHER_PATH = "/StatusNotifierWatcher"
ITEM_INTERFACES = (
    "org.kde.StatusNotifierItem",
    "org.freedesktop.StatusNotifierItem",
)
MENU = "com.canonical.dbusmenu"
TARGET_ITEM = "display pilot 2"
TARGET_MENU_LABEL = "minimize display pilot 2"
TIMEOUT_SECONDS = 1


def normalize(value):
    return str(value or "").replace("_", "").replace("&", "").strip().lower()


def get_property(bus, service, path, iface, name):
    properties = dbus.Interface(bus.get_object(service, path), PROPERTIES)
    return properties.Get(iface, name, timeout=TIMEOUT_SECONDS)


def split_status_notifier_item(item):
    item = str(item)
    if "@/" in item:
        service, path = item.split("@", 1)
    else:
        service, separator, path_suffix = item.partition("/")
        if not separator:
            return None
        path = f"/{path_suffix}"

    if service and path.startswith("/"):
        return service, path
    return None


def registered_items(bus):
    items = get_property(
        bus,
        WATCHER,
        WATCHER_PATH,
        WATCHER,
        "RegisteredStatusNotifierItems",
    )
    return filter(None, (split_status_notifier_item(item) for item in items))


def is_display_pilot_item(bus, service, path):
    for iface in ITEM_INTERFACES:
        for name in ("Title", "Id"):
            try:
                value = get_property(bus, service, path, iface, name)
            except DBusException:
                continue

            if TARGET_ITEM in normalize(value):
                return True
    return False


def item_menu_path(bus, service, path):
    for iface in ITEM_INTERFACES:
        try:
            value = get_property(bus, service, path, iface, "Menu")
        except DBusException:
            continue

        if value and str(value) != "/":
            return str(value)
    return None


def matching_menu_item_id(node):
    node_id, properties, children = node
    if TARGET_MENU_LABEL in normalize(properties.get("label")):
        return int(node_id)

    for child in children:
        match = matching_menu_item_id(child)
        if match is not None:
            return match

    return None


def click_minimize_menu_item(bus, service, path):
    menu = dbus.Interface(bus.get_object(service, path), MENU)

    try:
        menu.AboutToShow(dbus.Int32(0), timeout=TIMEOUT_SECONDS)
    except DBusException:
        pass

    _, layout = menu.GetLayout(
        dbus.Int32(0),
        dbus.Int32(-1),
        dbus.Array(["label"], signature="s"),
        timeout=TIMEOUT_SECONDS,
    )
    item_id = matching_menu_item_id(layout)
    if item_id is None:
        return False

    menu.Event(
        dbus.Int32(item_id),
        "clicked",
        dbus.String("", variant_level=1),
        dbus.UInt32(0),
        timeout=TIMEOUT_SECONDS,
    )
    print(f"Clicked '{TARGET_MENU_LABEL}' on {service}{path}.")
    return True


def main():
    bus = dbus.SessionBus()

    try:
        items = list(registered_items(bus))
    except DBusException as error:
        print(f"StatusNotifierWatcher is not ready: {error}", file=sys.stderr)
        return 1

    for service, item_path in items:
        if not is_display_pilot_item(bus, service, item_path):
            continue

        menu_path = item_menu_path(bus, service, item_path)
        if not menu_path:
            continue

        try:
            if click_minimize_menu_item(bus, service, menu_path):
                return 0
        except DBusException as error:
            print(f"{service}{menu_path}: {error}", file=sys.stderr)

    print(
        f"No Display Pilot 2 tray item with '{TARGET_MENU_LABEL}' found.",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
