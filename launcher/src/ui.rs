use crate::apps::{self, AppInfo, AppScanner};
use crate::config::{get_user_css_path, Config};
use crate::search::SearchEngine;
use crate::theme::ThemeManager;
use gtk4 as gtk;
use gtk4::glib;
use gtk4::prelude::*;
use gtk4_layer_shell::{Edge, KeyboardMode, Layer, LayerShell};
use std::cell::RefCell;
use std::path::Path;
use std::rc::Rc;

const MAX_DISPLAY_APPS: usize = 64;
const COLUMNS_PER_ROW: usize = 6;

pub struct LauncherState {
    pub window: gtk::ApplicationWindow,
    pub entry: gtk::Entry,
    pub flow_box: gtk::FlowBox,
    pub scrolled_window: gtk::ScrolledWindow,
    pub apps: Vec<AppInfo>,
    pub cards: Vec<gtk::Box>,
    pub filtered_indices: Vec<usize>,
    pub selected_index: usize,
    pub search_engine: SearchEngine,
    pub scanner: AppScanner,
    pub theme_manager: ThemeManager,
    pub css_provider: gtk::CssProvider,
    pub _hold_guard: gio::ApplicationHoldGuard,
    pub is_daemon: bool,
    pub is_open: bool,
    pub as_window: bool,
}

pub struct LauncherUi {
    state: Rc<RefCell<LauncherState>>,
}

impl LauncherUi {
    pub fn new(app: &gtk::Application, is_daemon: bool) -> Self {
        let config = Config::default();

        // 1. Scan applications
        let mut scanner = AppScanner::new();
        let apps = scanner.scan();
        let search_engine = SearchEngine::new();
        let filtered_indices: Vec<usize> = (0..apps.len()).collect();

        // 2. Setup Theme & CSS
        let theme_manager = ThemeManager::new();
        let css_provider = setup_css(&theme_manager);

        // 3. Create Layer Shell Window
        let target_monitor_name = std::env::var("GLASS_LAUNCHER_MONITOR").ok();
        let mut chosen_monitor: Option<gdk4::Monitor> = None;
        let mut chosen_geom = (1366, 768);

        if let Some(display) = gdk4::Display::default() {
            let monitors = display.monitors();
            for i in 0..monitors.n_items() {
                if let Some(mon) = monitors.item(i).and_then(|m| m.downcast::<gdk4::Monitor>().ok()) {
                    let matches = match (&target_monitor_name, mon.connector()) {
                        (Some(target), Some(conn)) => conn.as_str() == target,
                        _ => false,
                    };
                    if matches {
                        let geom = mon.geometry();
                        chosen_geom = (geom.width(), geom.height());
                        chosen_monitor = Some(mon);
                        break;
                    }
                }
            }
            if chosen_monitor.is_none() {
                if let Some(first) = monitors.item(0).and_then(|m| m.downcast::<gdk4::Monitor>().ok()) {
                    let geom = first.geometry();
                    chosen_geom = (geom.width(), geom.height());
                }
            }
        }

        let as_window = std::env::var("GLASS_LAUNCHER_WINDOW").map(|v| v == "1").unwrap_or(false)
            || std::env::args().any(|a| a == "--window" || a == "-w");

        let window = gtk::ApplicationWindow::new(app);
        if !as_window {
            window.init_layer_shell();
            window.set_layer(Layer::Overlay);
            if let Some(ref mon) = chosen_monitor {
                window.set_monitor(Some(mon));
            }
            window.set_keyboard_mode(if is_daemon {
                KeyboardMode::None
            } else {
                KeyboardMode::Exclusive
            });
            window.set_namespace(Some("glass-launcher"));
            window.set_default_size(chosen_geom.0, chosen_geom.1);

            window.set_anchor(Edge::Top, true);
            window.set_anchor(Edge::Bottom, true);
            window.set_anchor(Edge::Left, true);
            window.set_anchor(Edge::Right, true);
            window.set_exclusive_zone(-1);
        } else {
            window.set_title(Some("glass-launcher"));
            window.set_decorated(false);
            window.set_default_size(chosen_geom.0, chosen_geom.1);
        }
        window.set_visible(!is_daemon);
        window.add_css_class("launcher-window");

        // 4. Outer overlay container (for click-to-exit on background)
        let overlay = gtk::Box::new(gtk::Orientation::Vertical, 0);
        overlay.set_hexpand(true);
        overlay.set_vexpand(true);
        overlay.add_css_class("main-wrapper");

        // 5. Search Bar Container
        let search_container = gtk::Box::new(gtk::Orientation::Horizontal, 12);
        search_container.add_css_class("search-container");
        search_container.set_halign(gtk::Align::Center);
        search_container.set_valign(gtk::Align::Start);
        search_container.set_width_request(480);

        let search_icon = gtk::Label::new(Some(""));
        search_icon.add_css_class("search-icon");
        search_container.append(&search_icon);

        let entry = gtk::Entry::new();
        entry.add_css_class("search-entry");
        entry.set_placeholder_text(Some(&config.placeholder));
        entry.set_hexpand(true);
        entry.set_can_focus(true);
        search_container.append(&entry);

        overlay.append(&search_container);

        // 6. Grid Scrolled Window & FlowBox
        let scrolled_window = gtk::ScrolledWindow::new();
        scrolled_window.add_css_class("grid-scroll");
        scrolled_window.set_policy(gtk::PolicyType::Never, gtk::PolicyType::Automatic);
        scrolled_window.set_hexpand(true);
        scrolled_window.set_vexpand(true);
        scrolled_window.set_propagate_natural_width(false);
        scrolled_window.set_propagate_natural_height(false);
        scrolled_window.set_kinetic_scrolling(true);
        scrolled_window.set_overlay_scrolling(true);

        let vadj = scrolled_window.vadjustment();
        vadj.set_step_increment(60.0);

        let flow_box = gtk::FlowBox::new();
        flow_box.add_css_class("grid-container");
        flow_box.set_max_children_per_line(COLUMNS_PER_ROW as u32);
        flow_box.set_min_children_per_line(COLUMNS_PER_ROW as u32);
        flow_box.set_column_spacing(16);
        flow_box.set_row_spacing(12);
        flow_box.set_homogeneous(true);
        flow_box.set_halign(gtk::Align::Center);
        flow_box.set_valign(gtk::Align::Start);
        flow_box.set_selection_mode(gtk::SelectionMode::None);

        scrolled_window.set_child(Some(&flow_box));
        overlay.append(&scrolled_window);

        window.set_child(Some(&overlay));

        // 7. Pre-create Card widgets for all scanned applications
        let mut cards = Vec::with_capacity(apps.len());
        for (idx, app_info) in apps.iter().enumerate() {
            let card = create_app_card(idx, app_info, config.icon_size);
            cards.push(card);
        }

        let state = Rc::new(RefCell::new(LauncherState {
            window: window.clone(),
            entry: entry.clone(),
            flow_box: flow_box.clone(),
            scrolled_window,
            apps,
            cards,
            filtered_indices,
            selected_index: 0,
            search_engine,
            scanner,
            theme_manager,
            css_provider,
            _hold_guard: app.hold(),
            is_daemon,
            is_open: !is_daemon,
            as_window,
        }));

        let ui = Self { state };

        // 8. Connect Card Click Handlers
        ui.setup_card_clicks();

        // 9. Connect Background Click Handler
        ui.setup_background_click(&overlay);

        // 10. Connect Search Input Text Change
        ui.setup_search_handler();

        // 11. Connect Keyboard Events (Arrows, Enter, Escape)
        ui.setup_key_handler();

        // 12. Populate Initial Grid
        ui.refresh_grid();

        ui
    }

    #[allow(dead_code)]
    pub fn window(&self) -> gtk::ApplicationWindow {
        self.state.borrow().window.clone()
    }

    pub fn reload_theme(&self) {
        let mut state = self.state.borrow_mut();
        state.theme_manager.reload();
        apply_css(&state.theme_manager, &state.css_provider);
    }

    pub fn check_and_reload_theme(&self) {
        let mut state = self.state.borrow_mut();
        if state.theme_manager.check_needs_reload() {
            state.theme_manager.reload();
            apply_css(&state.theme_manager, &state.css_provider);
        }
    }

    pub fn show(&self) {
        self.check_and_reload_theme();

        let mut state = self.state.borrow_mut();
        state.is_open = true;
        let had_query = !state.entry.text().is_empty();
        if had_query {
            state.entry.set_text("");
        }
        if !state.as_window {
            state.window.set_keyboard_mode(KeyboardMode::Exclusive);
        }
        state.window.set_visible(true);
        state.window.present();
        state.entry.grab_focus();
        drop(state);

        self.check_and_reload_apps();
        if had_query {
            self.update_search("");
        } else {
            self.update_selection(0);
        }
    }

    pub fn hide(&self) {
        let mut state = self.state.borrow_mut();
        state.is_open = false;
        if !state.as_window {
            state.window.set_keyboard_mode(KeyboardMode::None);
        }
        if state.is_daemon {
            state.window.set_visible(false);
        } else if let Some(app) = state.window.application() {
            app.quit();
        } else {
            state.window.close();
        }
    }

    pub fn toggle(&self) {
        let is_open = self.state.borrow().is_open;
        if is_open {
            self.hide();
        } else {
            self.show();
        }
    }

    fn check_and_reload_apps(&self) {
        let mut state = self.state.borrow_mut();
        if state.scanner.check_needs_reload() {
            let new_apps = state.scanner.scan();
            let mut new_cards = Vec::with_capacity(new_apps.len());
            for (idx, app_info) in new_apps.iter().enumerate() {
                new_cards.push(create_app_card(idx, app_info, 64));
            }
            state.apps = new_apps;
            state.cards = new_cards;
            drop(state);
            self.setup_card_clicks();
        }
    }

    fn setup_card_clicks(&self) {
        let state = self.state.borrow();
        for (idx, card) in state.cards.iter().enumerate() {
            let gesture = gtk::GestureClick::new();
            let self_clone = self.clone();
            gesture.connect_released(move |_, _, _, _| {
                self_clone.launch_by_app_index(idx);
            });
            card.add_controller(gesture);
        }
    }

    fn setup_background_click(&self, overlay: &gtk::Box) {
        let gesture = gtk::GestureClick::new();
        let self_clone = self.clone();
        gesture.connect_released(move |g, _, x, y| {
            if let Some(widget) = g.widget() {
                if let Some(picked) = widget.pick(x, y, gtk::PickFlags::DEFAULT) {
                    if picked == widget || picked.has_css_class("main-wrapper") {
                        self_clone.hide();
                    }
                }
            }
        });
        overlay.add_controller(gesture);
    }

    fn setup_search_handler(&self) {
        let entry = self.state.borrow().entry.clone();
        let self_clone = self.clone();
        entry.connect_changed(move |e| {
            let text = e.text();
            self_clone.update_search(&text);
        });

        let self_activate = self.clone();
        entry.connect_activate(move |_| {
            self_activate.launch_selected();
        });
    }

    fn update_search(&self, query: &str) {
        let mut state = self.state.borrow_mut();
        let matched = state.search_engine.filter_indices(&state.apps, query);
        if matched == state.filtered_indices && state.flow_box.first_child().is_some() {
            state.selected_index = 0;
            drop(state);
            self.update_selection(0);
            return;
        }
        state.filtered_indices = matched;
        state.selected_index = 0;
        drop(state);

        self.refresh_grid();
    }

    fn refresh_grid(&self) {
        let state = self.state.borrow();
        let flow_box = &state.flow_box;

        // Clear current visible items
        while let Some(child) = flow_box.first_child() {
            flow_box.remove(&child);
        }

        // Add top matches
        for (display_idx, &app_idx) in state
            .filtered_indices
            .iter()
            .take(MAX_DISPLAY_APPS)
            .enumerate()
        {
            let card = &state.cards[app_idx];
            if display_idx == state.selected_index {
                card.add_css_class("selected");
            } else {
                card.remove_css_class("selected");
            }
            flow_box.insert(card, -1);
        }

        // Scroll back to top
        let vadj = state.scrolled_window.vadjustment();
        vadj.set_value(0.0);
    }

    fn update_selection(&self, new_index: usize) {
        let mut state = self.state.borrow_mut();
        let count = state.filtered_indices.len().min(MAX_DISPLAY_APPS);
        if count == 0 {
            return;
        }

        let clamped = new_index.min(count - 1);
        let old_index = state.selected_index;
        state.selected_index = clamped;

        // Update CSS classes
        if let Some(&old_app_idx) = state.filtered_indices.get(old_index) {
            state.cards[old_app_idx].remove_css_class("selected");
        }
        if let Some(&new_app_idx) = state.filtered_indices.get(clamped) {
            let card = &state.cards[new_app_idx];
            card.add_css_class("selected");

            // Ensure visible in ScrolledWindow with accurate row tracking
            let vadj = state.scrolled_window.vadjustment();
            let row = clamped / COLUMNS_PER_ROW;
            let row_height = 125.0;
            let target_top = (row as f64) * row_height;
            let target_bottom = target_top + row_height;
            let current_val = vadj.value();
            let page_size = vadj.page_size();

            if target_bottom > current_val + page_size {
                vadj.set_value(target_bottom - page_size + 12.0);
            } else if target_top < current_val {
                vadj.set_value((target_top - 12.0).max(0.0));
            }
        }
    }

    fn setup_key_handler(&self) {
        let key_controller = gtk::EventControllerKey::new();
        key_controller.set_propagation_phase(gtk::PropagationPhase::Capture);
        let self_clone = self.clone();

        key_controller.connect_key_pressed(move |_, keyval, _keycode, _state| {
            match keyval {
                gdk4::Key::Escape => {
                    self_clone.hide();
                    glib::Propagation::Stop
                }
                gdk4::Key::Return | gdk4::Key::KP_Enter => {
                    self_clone.launch_selected();
                    glib::Propagation::Stop
                }
                gdk4::Key::Down => {
                    let current = self_clone.state.borrow().selected_index;
                    self_clone.update_selection(current + COLUMNS_PER_ROW);
                    glib::Propagation::Stop
                }
                gdk4::Key::Up => {
                    let current = self_clone.state.borrow().selected_index;
                    self_clone.update_selection(current.saturating_sub(COLUMNS_PER_ROW));
                    glib::Propagation::Stop
                }
                gdk4::Key::Right => {
                    let current = self_clone.state.borrow().selected_index;
                    self_clone.update_selection(current + 1);
                    glib::Propagation::Stop
                }
                gdk4::Key::Left => {
                    let current = self_clone.state.borrow().selected_index;
                    self_clone.update_selection(current.saturating_sub(1));
                    glib::Propagation::Stop
                }
                gdk4::Key::Tab => {
                    let current = self_clone.state.borrow().selected_index;
                    let count = self_clone.state.borrow().filtered_indices.len().min(MAX_DISPLAY_APPS);
                    if count > 0 {
                        self_clone.update_selection((current + 1) % count);
                    }
                    glib::Propagation::Stop
                }
                gdk4::Key::ISO_Left_Tab => {
                    let current = self_clone.state.borrow().selected_index;
                    let count = self_clone.state.borrow().filtered_indices.len().min(MAX_DISPLAY_APPS);
                    if count > 0 {
                        self_clone.update_selection((current + count - 1) % count);
                    }
                    glib::Propagation::Stop
                }
                _ => glib::Propagation::Proceed,
            }
        });

        self.state.borrow().window.add_controller(key_controller);
    }

    fn launch_selected(&self) {
        let mut state = self.state.borrow_mut();
        if !state.is_open {
            return;
        }
        if let Some(&app_idx) = state.filtered_indices.get(state.selected_index) {
            let app = &state.apps[app_idx];
            let _ = apps::launch_app(app);
            state.is_open = false;
            drop(state);
            self.hide();
        }
    }

    fn launch_by_app_index(&self, app_idx: usize) {
        let state = self.state.borrow();
        if let Some(app) = state.apps.get(app_idx) {
            let _ = apps::launch_app(app);
            drop(state);
            self.hide();
        }
    }
}

impl Clone for LauncherUi {
    fn clone(&self) -> Self {
        Self {
            state: self.state.clone(),
        }
    }
}

fn create_app_card(_app_idx: usize, app: &AppInfo, icon_size: i32) -> gtk::Box {
    let card = gtk::Box::new(gtk::Orientation::Vertical, 6);
    card.add_css_class("app-card");
    card.set_halign(gtk::Align::Center);
    card.set_valign(gtk::Align::Center);
    card.set_cursor_from_name(Some("pointer"));
    card.set_width_request(150);

    // Icon
    let image = gtk::Image::new();
    image.add_css_class("app-icon");
    if Path::new(&app.icon).is_absolute() && Path::new(&app.icon).exists() {
        image.set_from_file(Some(Path::new(&app.icon)));
    } else {
        image.set_icon_name(Some(&app.icon));
    }
    image.set_pixel_size(icon_size);
    card.append(&image);

    // Label
    let label = gtk::Label::new(Some(&app.name));
    label.add_css_class("app-label");
    label.set_wrap(true);
    label.set_wrap_mode(gtk::pango::WrapMode::WordChar);
    label.set_lines(2);
    label.set_width_chars(12);
    label.set_max_width_chars(15);
    label.set_justify(gtk::Justification::Center);
    label.set_ellipsize(gtk::pango::EllipsizeMode::End);
    label.set_halign(gtk::Align::Center);
    card.append(&label);

    card
}

fn apply_css(theme_manager: &ThemeManager, provider: &gtk::CssProvider) {
    let mut css_content = theme_manager.generate_css();
    if let Some(user_css) = get_user_css_path() {
        if user_css.is_file() {
            if let Ok(custom) = std::fs::read_to_string(&user_css) {
                css_content.push_str("\n/* User Custom CSS Overrides */\n");
                css_content.push_str(&custom);
            }
        }
    }

    provider.load_from_data(&css_content);
}

fn setup_css(theme_manager: &ThemeManager) -> gtk::CssProvider {
    let provider = gtk::CssProvider::new();
    apply_css(theme_manager, &provider);

    if let Some(display) = gdk4::Display::default() {
        gtk::style_context_add_provider_for_display(
            &display,
            &provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );
    }
    provider
}
