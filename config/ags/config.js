import App from 'resource:///com/github/aylur/ags/app.js';
import Widget from 'resource:///com/github/aylur/ags/widget.js';
import Hyprland from 'resource:///com/github/aylur/ags/service/hyprland.js';
import SystemTray from 'resource:///com/github/aylur/ags/service/systemtray.js';

// --- Workspaces (Left) ---
const Workspaces = () => Widget.Box({
    className: 'workspaces pill',
    children: Hyprland.bind('workspaces').transform(ws => {
        return ws.sort((a, b) => a.id - b.id).map(({ id }) => Widget.Button({
            onClicked: () => Hyprland.sendMessage(`dispatch workspace ${id}`),
            child: Widget.Label(`${id}`),
            className: Hyprland.active.workspace.bind('id')
                .transform(active => active === id ? 'focused' : ''),
        }));
    }),
});

// --- Client Title (Center) ---
const ClientTitle = () => Widget.Box({
    className: 'pill',
    child: Widget.Label({
        label: Hyprland.active.client.bind('title').transform(t => t || 'Desktop'),
    }),
});

// --- Status Modules (Right) ---
const Clock = () => Widget.Label({
    className: 'clock pill',
    setup: self => self.poll(1000, self => {
        self.label = new Date().toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
    }),
});

const SysTray = () => Widget.Box({
    className: 'tray pill',
    children: SystemTray.bind('items').transform(items => {
        return items.map(item => Widget.Button({
            child: Widget.Icon({ bindProperty: ['icon', item, 'icon'] }),
            onPrimaryClick: (_, event) => item.activate(event),
        }));
    }),
});

// --- Bar Layout ---
const Bar = (monitor = 0) => Widget.Window({
    name: `bar-${monitor}`,
    className: 'bar-window',
    monitor,
    anchor: ['top', 'left', 'right'],
    exclusivity: 'exclusive',
    child: Widget.CenterBox({
        startWidget: Widget.Box({ spacing: 8, children: [Workspaces()] }),
        centerWidget: ClientTitle(),
        endWidget: Widget.Box({ 
            hpack: 'end', 
            spacing: 8, 
            children: [SysTray(), Clock()] 
        }),
    }),
});

App.config({
    style: './style.css',
    windows: [Bar()],
});
