/*
 * Copyright © 2013–2014 Tom Beckmann <tomjonabc@gmail.com>
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

public class SettingsWindow : Gtk.Dialog {

	public SettingsWindow() {
		title = _("Preferences");

		add_buttons(Gtk.Stock.CLOSE, Gtk.ResponseType.CANCEL);

		var dimensions_columns = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		var dimensions_rows = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		var rows = new Gtk.SpinButton.with_range(10, 200, 1);
		var columns = new Gtk.SpinButton.with_range(10, 300, 1);

		rows.value = Settings.get_default().terminal_lines;
		rows.value_changed.connect(() => {
			Settings.get_default().terminal_lines = (int)rows.value;
		});

		columns.value = Settings.get_default().terminal_columns;
		columns.value_changed.connect(() => {
			Settings.get_default().terminal_columns = (int)columns.value;
		});

		dimensions_columns.pack_start(columns, false);
		dimensions_columns.pack_start(new Gtk.Label(_("columns")), false);
		dimensions_rows.pack_start(rows, false);
		dimensions_rows.pack_start(new Gtk.Label(_("rows")), false);

		var status_bar_left = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		var left = new Gtk.Entry ();
		left.text = Settings.get_default().status_bar_left;
		left.changed.connect(() => {
			Settings.get_default().status_bar_left = left.text;
		});
		status_bar_left.pack_start(left, false);
		status_bar_left.pack_start(new Gtk.Label(_("Left")), false);

		var status_bar_middle = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		var middle = new Gtk.Entry ();
		middle.text = Settings.get_default().status_bar_middle;
		middle.changed.connect(() => {
			Settings.get_default().status_bar_middle = middle.text;
		});
		status_bar_middle.pack_start(middle, false);
		status_bar_middle.pack_start(new Gtk.Label(_("Middle")), false);

		var status_bar_right = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		var right = new Gtk.Entry ();
		right.text = Settings.get_default().status_bar_right;
		right.changed.connect(() => {
			Settings.get_default().status_bar_right = right.text;
		});
		status_bar_right.pack_start(right, false);
		status_bar_right.pack_start(new Gtk.Label(_("Right")), false);


		var terminal_font = new Gtk.FontButton();
		terminal_font.use_font = true;
		// Restrict selection to monospaced fonts
		terminal_font.set_filter_func((family, face) => {
			return family.is_monospace();
		});
		terminal_font.font_name = Settings.get_default().terminal_font_name;
		terminal_font.font_set.connect(() => {
			Settings.get_default().terminal_font_name = terminal_font.font_name;
		});

		var label_font = new Gtk.FontButton();
		label_font.use_font = true;
		label_font.font_name = Settings.get_default().label_font_name;
		label_font.font_set.connect(() => {
			Settings.get_default().label_font_name = label_font.font_name;
		});

		var dark_look = new Gtk.Switch();
		dark_look.active = Settings.get_default().dark;
		dark_look.halign = Gtk.Align.START;
		dark_look.notify["active"].connect(() => {
			Settings.get_default().dark = dark_look.active;
		});

		var color_scheme = new Gtk.ComboBoxText();
		foreach (var color_scheme_name in FinalTerm.color_schemes.keys) {
			color_scheme.append(color_scheme_name, color_scheme_name);
		}
		color_scheme.active_id = Settings.get_default().color_scheme_name;
		color_scheme.changed.connect(() => {
			Settings.get_default().color_scheme_name = color_scheme.active_id;
		});

		var theme = new Gtk.ComboBoxText();
		foreach (var theme_name in FinalTerm.themes.keys) {
			theme.append(theme_name, theme_name);
		}
		theme.active_id = Settings.get_default().theme_name;
		theme.changed.connect(() => {
			Settings.get_default().theme_name = theme.active_id;
		});

		var opacity = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1);
		opacity.set_value(Settings.get_default().opacity * 100.0);
		opacity.value_changed.connect(() => {
			Settings.get_default().opacity = opacity.get_value() / 100.0;
		});

		var grid = new Gtk.Grid();
		grid.column_homogeneous = true;
		grid.column_spacing = 12;
		grid.row_spacing = 6;
		grid.margin = 12;

		grid.attach(create_header(_("General")), 0, 0, 1, 1);

		grid.attach(create_label(_("Default dimensions:")), 0, 1, 1, 1);
		grid.attach(dimensions_columns, 1, 1, 1, 1);
		grid.attach(dimensions_rows, 1, 2, 1, 1);

		grid.attach(create_label(_("Status Bar:")), 0, 3, 1, 1);
		grid.attach(status_bar_left, 1, 3, 1, 1);
		grid.attach(status_bar_middle, 1, 4, 1, 1);
		grid.attach(status_bar_right, 1, 5, 1, 1);

		grid.attach(create_header(_("Appearance")), 0, 6, 1, 1);

		grid.attach(create_label(_("Terminal font:")), 0, 7, 1, 1);
		grid.attach(terminal_font, 1, 7, 1, 1);

		grid.attach(create_label(_("Label font:")), 0, 8, 1, 1);
		grid.attach(label_font, 1, 8, 1, 1);

		grid.attach(create_label(_("Dark look:")), 0, 9, 1, 1);
		grid.attach(dark_look, 1, 9, 1, 1);

		grid.attach(create_label(_("Color scheme:")), 0, 10, 1, 1);
		grid.attach(color_scheme, 1, 10, 1, 1);

		grid.attach(create_label(_("Theme:")), 0, 11, 1, 1);
		grid.attach(theme, 1, 11, 1, 1);

		// TODO: This looks ugly (alignment)
		grid.attach(create_label(_("Opacity:")), 0, 12, 1, 1);
		grid.attach(opacity, 1, 12, 1, 1);

		get_content_area().add(grid);
	}

	private Gtk.Label create_header(string title) {
		var label = new Gtk.Label("<span weight='bold'>" + title + "</span>");
		label.use_markup = true;
		label.halign = Gtk.Align.START;
		return label;
	}

	private Gtk.Label create_label(string text) {
		var label = new Gtk.Label(text);
		label.halign = Gtk.Align.END;
		return label;
	}

}
