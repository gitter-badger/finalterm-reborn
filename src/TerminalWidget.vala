/*
 * Copyright © 2013–2014 Philipp Emanuel Weidmann <pew@worldwidemann.com>
 * Copyright © 2015 RedHatter <timothy@idioticdev.com>
 *
 * Nemo vir est qui mundum non reddat meliorem.
 *
 *
 * This file is part of Final Term.
 *
 * Final Term is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Final Term is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Final Term.  If not, see <http://www.gnu.org/licenses/>.
 */

public class TerminalWidget : Gtk.EventBox, NestingContainerChild {

	public bool is_active { get; set; }

	public string title { get; set; }

	private Terminal terminal;
	private TerminalView terminal_view;

	// This has to be a field rather than a local variable
	// because it gets destroyed immediately otherwise
	private Gtk.Menu context_menu;

	public TerminalWidget() {
		terminal = new Terminal();

		title = terminal.terminal_output.terminal_title;
		terminal.terminal_output.notify["terminal-title"].connect(() => {
			title = terminal.terminal_output.terminal_title;
		});

		bool shell_terminated_called = false;
		bool close_called = false;

		terminal.shell_terminated.connect(() => {
			shell_terminated_called = true;
			if (!close_called) {
				// Triggered by the Posix SIGCHLD signal, the shell_terminated signal
				// is called from a separate thread. To safely call GTK+ functions,
				// the close signal needs to be emitted on the GTK+ main thread.
				Gdk.threads_add_idle(() => {
					close();
					return false;
				});
			}
		});

		var confirm_close = false;
		close.connect(() => {
			if (confirm_close || !terminal.has_child()) {
				close_called = true;
				if (!shell_terminated_called)
					terminal.terminate_shell();

				return;
			}

			Gtk.MessageDialog msg = new Gtk.MessageDialog (get_toplevel() as Gtk.Window,
								Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING,
								Gtk.ButtonsType.CANCEL, _("Close this terminal?"));
			msg.secondary_text = _("There is still a process running in this terminal. Closing the terminal will kill it.");
			msg.add_button(_("Close Terminal"), Gtk.ResponseType.OK);
			msg.response.connect ((response) => {
				msg.destroy();
				if (response == Gtk.ResponseType.OK) {
					confirm_close = true;
					close();
				}
			});
			msg.show ();

			Signal.stop_emission_by_name (this, "close");
		});


		terminal_view = new TerminalView(terminal);
		terminal.terminal_view = terminal_view;
		add (terminal_view);
		((Gtk.TextView)terminal_view.terminal_output_view.get_children().nth_data(0))
			.populate_popup.connect((menu) => {
				var children = menu.get_children();
				for (var i = 0; i < children.length(); i++)
					menu.remove(children.nth_data(i));

				foreach (var item in get_menu_items())
					menu.append(item);

				menu.show_all();
			});

		var inactive_effect = new Gtk.DrawingArea ();
		inactive_effect.get_style_context ().add_class("inactive-effect");
		terminal_view.put(inactive_effect, 0, 0);
		terminal_view.size_allocate.connect((alloc) => {
			var child = Gtk.Allocation ();
			child.x = 0;
			child.y = 0;
			child.width = alloc.width;
			child.height = alloc.height;
			inactive_effect.size_allocate (child);
		});
		inactive_effect.hide ();
		inactive_effect.no_show_all = true;

		notify["is-active"].connect(() => {
			if (is_active)
				inactive_effect.hide ();
			else
				inactive_effect.show ();

			terminal_view.terminal_output_view.is_active = is_active;
		});
	}

	protected override void get_preferred_width(out int minimum_width, out int natural_width) {
		natural_width = terminal_view.terminal_output_view.get_horizontal_padding() +
				(terminal.columns * Settings.get_default().character_width);
		minimum_width = 2;
	}

	protected override void get_preferred_height(out int minimum_height, out int natural_height) {
		terminal_view.get_preferred_height(null, out natural_height);
		minimum_height = 2;
	}

	public void clear_shell_command() {
		terminal.clear_command();
	}

	public void set_shell_command(string command) {
		terminal.set_command(command);
	}

	public void run_shell_command(string command) {
		terminal.run_command(command);
	}

	public void send_text_to_shell(string text) {
		terminal.send_text(text);
	}

	public TerminalOutput.TerminalMode get_terminal_modes() {
		return terminal.terminal_output.terminal_modes;
	}

	public override bool configure_event(Gdk.EventConfigure event) {
		// Reposition autocompletion popup when window is moved or resized
		// to make it "stick" to the prompt line
		if (FinalTerm.autocompletion.is_popup_visible()) {
			terminal.update_autocompletion_position();
		}

		return false;
	}

	public override bool button_press_event(Gdk.EventButton event) {
		if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
			// Left mouse button pressed
			is_active = true;
			return true;
		} else if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
			// Right mouse button pressed
			get_context_menu().popup(null, null, null, event.button, event.time);
			return true;
		}

		return false;
	}

	private Gtk.MenuItem[] get_menu_items() {
		var items = new Gee.ArrayList<Gtk.MenuItem>();
		Gtk.MenuItem menu_item;

		menu_item = new Gtk.MenuItem.with_label(_("New Tab"));
		menu_item.activate.connect(() => {
			add_tab();
		});
		items.add(menu_item);

		items.add(new Gtk.SeparatorMenuItem());

		menu_item = new Gtk.MenuItem.with_label(_("Split Horizontally"));
		menu_item.activate.connect(() => {
			split(Gtk.Orientation.HORIZONTAL);
		});
		items.add(menu_item);

		menu_item = new Gtk.MenuItem.with_label(_("Split Vertically"));
		menu_item.activate.connect(() => {
			split(Gtk.Orientation.VERTICAL);
		});
		items.add(menu_item);

		items.add(new Gtk.SeparatorMenuItem());

		menu_item = new Gtk.MenuItem.with_label(_("Copy Last Command"));
		menu_item.activate.connect(() => {
			Utilities.set_clipboard_text(terminal.terminal_output.last_command);
		});
		items.add(menu_item);

		menu_item = new Gtk.MenuItem.with_label(_("Paste"));
		menu_item.activate.connect(() => {
			send_text_to_shell(Utilities.get_clipboard_text());
		});
		items.add(menu_item);

		if (terminal.terminal_output.has_selection) {
			menu_item = new Gtk.MenuItem.with_label(_("Copy"));
			menu_item.activate.connect(() =>
				terminal.terminal_output.copy_clipboard(Utilities.get_clipboard()));
			items.add(menu_item);
		}

		items.add(new Gtk.SeparatorMenuItem());

		menu_item = new Gtk.MenuItem.with_label(_("Close"));
		menu_item.activate.connect(() => {
			close();
		});
		items.add(menu_item);

		return items.to_array();
	}

	private Gtk.Menu get_context_menu() {
		context_menu = new Gtk.Menu();

		foreach (var item in get_menu_items())
			context_menu.append(item);

		context_menu.show_all();

		return context_menu;
	}
}
