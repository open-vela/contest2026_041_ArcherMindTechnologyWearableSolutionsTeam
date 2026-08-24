/****************************************************************************
 * apps/examples/elderly/ui_settings.c
 *
 * Settings page: brightness, collection interval, toggles, upload mode.
 * Adapted for 454x454 circular display.
 ****************************************************************************/

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include "ui_settings.h"
#include "ui_manager.h"
#include "http_client.h"

/****************************************************************************
 * Private Data
 ****************************************************************************/

static lv_obj_t *g_brightness_slider;
static lv_obj_t *g_interval_label;
static lv_obj_t *g_sos_switch;
static lv_obj_t *g_fall_switch;
static lv_obj_t *g_sim_switch;
static lv_obj_t *g_btn_mqtt;
static lv_obj_t *g_btn_http;
static lv_obj_t *g_conn_status_label;

/****************************************************************************
 * Private Functions
 ****************************************************************************/

/**
 * Brightness slider event handler.
 */

static void brightness_cb(lv_event_t *e)
{
  lv_obj_t *slider = lv_event_get_target(e);
  app_context_t *ctx = app_get_context();
  ctx->settings.brightness = lv_slider_get_value(slider);
}

/**
 * Interval +/- button event handler.
 */

static void interval_btn_cb(lv_event_t *e)
{
  int32_t delta = (int32_t)(intptr_t)lv_event_get_user_data(e);
  app_context_t *ctx = app_get_context();

  ctx->settings.collect_interval += delta;
  if (ctx->settings.collect_interval < 5)
    {
      ctx->settings.collect_interval = 5;
    }

  if (ctx->settings.collect_interval > 300)
    {
      ctx->settings.collect_interval = 300;
    }

  char buf[16];
  snprintf(buf, sizeof(buf), "%lds", (long)ctx->settings.collect_interval);
  lv_label_set_text(g_interval_label, buf);
}

/**
 * Switch event handler for toggles.
 */

static void switch_cb(lv_event_t *e)
{
  lv_obj_t *sw = lv_event_get_target(e);
  bool checked = lv_obj_has_state(sw, LV_STATE_CHECKED);
  int32_t id = (int32_t)(intptr_t)lv_event_get_user_data(e);
  app_context_t *ctx = app_get_context();

  switch (id)
    {
      case 0:
        ctx->settings.sos_enabled = checked;
        break;
      case 1:
        ctx->settings.fall_detect = checked;
        break;
      case 2:
        ctx->settings.use_sim_data = checked;
        break;
    }
}

/**
 * Upload mode button handler.
 */

static void upload_mode_cb(lv_event_t *e)
{
  bool use_mqtt = (bool)(intptr_t)lv_event_get_user_data(e);
  app_context_t *ctx = app_get_context();
  ctx->settings.use_mqtt = use_mqtt;

  /* Update button visual state */

  if (use_mqtt)
    {
      lv_obj_set_style_border_color(g_btn_mqtt, COLOR_BLUE, 0);
      lv_obj_set_style_text_color(g_btn_mqtt, COLOR_TEXT_PRIMARY, 0);
      lv_obj_set_style_border_color(g_btn_http, COLOR_BORDER, 0);
      lv_obj_set_style_text_color(g_btn_http, COLOR_TEXT_DIM, 0);
    }
  else
    {
      lv_obj_set_style_border_color(g_btn_http, COLOR_BLUE, 0);
      lv_obj_set_style_text_color(g_btn_http, COLOR_TEXT_PRIMARY, 0);
      lv_obj_set_style_border_color(g_btn_mqtt, COLOR_BORDER, 0);
      lv_obj_set_style_text_color(g_btn_mqtt, COLOR_TEXT_DIM, 0);
    }
}

/**
 * Save button event handler.
 */

static void save_btn_cb(lv_event_t *e)
{
  LV_UNUSED(e);

  /* TODO: Persist settings to NVS/flash */

  /* Show save confirmation */

  lv_label_set_text(g_conn_status_label, "Settings saved");
  lv_obj_set_style_text_color(g_conn_status_label, COLOR_GREEN, 0);
}

/**
 * Create a settings row with a label and a switch.
 */

static lv_obj_t *create_switch_row(lv_obj_t *parent, const char *label,
                                    bool initial, lv_obj_t **sw_out,
                                    int32_t id)
{
  lv_obj_t *row = lv_obj_create(parent);
  lv_obj_set_size(row, CONTENT_WIDTH, 40);
  lv_obj_set_style_bg_opa(row, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(row, 0, 0);
  lv_obj_set_style_pad_all(row, 0, 0);
  lv_obj_remove_flag(row, LV_OBJ_FLAG_SCROLLABLE);

  lv_obj_t *lbl = lv_label_create(row);
  lv_label_set_text(lbl, label);
  lv_obj_set_style_text_color(lbl, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(lbl, &lv_font_montserrat_14, 0);
  lv_obj_align(lbl, LV_ALIGN_LEFT_MID, 0, 0);

  *sw_out = lv_switch_create(row);
  lv_obj_set_size(*sw_out, 50, 26);
  lv_obj_align(*sw_out, LV_ALIGN_RIGHT_MID, 0, 0);
  lv_obj_set_style_bg_color(*sw_out, COLOR_CARD_BG2, 0);
  lv_obj_set_style_bg_color(*sw_out, COLOR_GREEN, LV_PART_INDICATOR |
                             LV_STATE_CHECKED);

  if (initial)
    {
      lv_obj_add_state(*sw_out, LV_STATE_CHECKED);
    }

  lv_obj_add_event_cb(*sw_out, switch_cb, LV_EVENT_VALUE_CHANGED,
                       (void *)(intptr_t)id);

  return row;
}

/**
 * Create a section label (visual divider).
 */

static lv_obj_t *create_section_spacer(lv_obj_t *parent, int height)
{
  lv_obj_t *spacer = lv_obj_create(parent);
  lv_obj_set_size(spacer, CONTENT_WIDTH, height);
  lv_obj_set_style_bg_opa(spacer, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(spacer, 0, 0);
  lv_obj_remove_flag(spacer, LV_OBJ_FLAG_SCROLLABLE);
  return spacer;
}

/****************************************************************************
 * Public Functions
 ****************************************************************************/

lv_obj_t *ui_settings_create(lv_obj_t *parent)
{
  app_context_t *ctx = app_get_context();

  lv_obj_t *page = lv_obj_create(parent);
  lv_obj_set_size(page, SCREEN_WIDTH, SCREEN_HEIGHT);
  lv_obj_set_style_bg_opa(page, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(page, 0, 0);
  lv_obj_set_style_pad_all(page, 0, 0);
  lv_obj_remove_flag(page, LV_OBJ_FLAG_SCROLLABLE);

  /* Title */

  lv_obj_t *title = lv_label_create(page);
  lv_label_set_text(title, "Settings");
  lv_obj_set_style_text_color(title, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(title, &lv_font_montserrat_14, 0);
  lv_obj_align(title, LV_ALIGN_TOP_MID, 0, SAFE_MARGIN + 5);

  /* Scrollable content area */

  int content_h = SCREEN_HEIGHT - 2 * SAFE_MARGIN - 50;

  lv_obj_t *content = lv_obj_create(page);
  lv_obj_set_size(content, CONTENT_WIDTH, content_h);
  lv_obj_align(content, LV_ALIGN_TOP_MID, 0, SAFE_MARGIN + 35);
  lv_obj_set_style_bg_opa(content, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(content, 0, 0);
  lv_obj_set_style_pad_all(content, 0, 0);
  lv_obj_set_style_pad_row(content, 8, 0);
  lv_obj_set_flex_flow(content, LV_FLEX_FLOW_COLUMN);
  lv_obj_set_scroll_dir(content, LV_DIR_VER);
  lv_obj_add_flag(content, LV_OBJ_FLAG_SCROLLABLE);

  /* --- Brightness --- */

  lv_obj_t *br_label = lv_label_create(content);
  lv_label_set_text(br_label, "Brightness");
  lv_obj_set_style_text_color(br_label, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(br_label, &lv_font_montserrat_14, 0);

  g_brightness_slider = lv_slider_create(content);
  lv_obj_set_width(g_brightness_slider, CONTENT_WIDTH);
  lv_slider_set_range(g_brightness_slider, 10, 100);
  lv_slider_set_value(g_brightness_slider, ctx->settings.brightness,
                       LV_ANIM_OFF);
  lv_obj_set_style_bg_color(g_brightness_slider, COLOR_PROGRESS_BG,
                              LV_PART_MAIN);
  lv_obj_set_style_bg_color(g_brightness_slider, COLOR_BLUE,
                              LV_PART_INDICATOR);
  lv_obj_set_style_bg_color(g_brightness_slider, COLOR_TEXT_PRIMARY,
                              LV_PART_KNOB);
  lv_obj_set_style_pad_all(g_brightness_slider, 4, LV_PART_KNOB);
  lv_obj_add_event_cb(g_brightness_slider, brightness_cb,
                       LV_EVENT_VALUE_CHANGED, NULL);

  create_section_spacer(content, 4);

  /* --- Collection Interval --- */

  lv_obj_t *intv_label = lv_label_create(content);
  lv_label_set_text(intv_label, "Interval");
  lv_obj_set_style_text_color(intv_label, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(intv_label, &lv_font_montserrat_14, 0);

  lv_obj_t *intv_row = lv_obj_create(content);
  lv_obj_set_size(intv_row, CONTENT_WIDTH, 36);
  lv_obj_set_style_bg_opa(intv_row, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(intv_row, 0, 0);
  lv_obj_set_style_pad_all(intv_row, 0, 0);
  lv_obj_remove_flag(intv_row, LV_OBJ_FLAG_SCROLLABLE);

  /* Minus button */

  lv_obj_t *btn_minus = lv_button_create(intv_row);
  lv_obj_set_size(btn_minus, 36, 30);
  lv_obj_set_style_radius(btn_minus, 6, 0);
  lv_obj_set_style_bg_color(btn_minus, COLOR_CARD_BG2, 0);
  lv_obj_set_style_border_width(btn_minus, 1, 0);
  lv_obj_set_style_border_color(btn_minus, COLOR_TEXT_DIM, 0);
  lv_obj_align(btn_minus, LV_ALIGN_LEFT_MID, 0, 0);
  lv_obj_t *minus_lbl = lv_label_create(btn_minus);
  lv_label_set_text(minus_lbl, "-");
  lv_obj_set_style_text_color(minus_lbl, COLOR_TEXT_PRIMARY, 0);
  lv_obj_center(minus_lbl);
  lv_obj_add_event_cb(btn_minus, interval_btn_cb, LV_EVENT_CLICKED,
                       (void *)(intptr_t)(-5));

  /* Interval value */

  char buf[16];
  snprintf(buf, sizeof(buf), "%lds", (long)ctx->settings.collect_interval);
  g_interval_label = lv_label_create(intv_row);
  lv_label_set_text(g_interval_label, buf);
  lv_obj_set_style_text_color(g_interval_label, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(g_interval_label, &lv_font_montserrat_16, 0);
  lv_obj_center(g_interval_label);

  /* Plus button */

  lv_obj_t *btn_plus = lv_button_create(intv_row);
  lv_obj_set_size(btn_plus, 36, 30);
  lv_obj_set_style_radius(btn_plus, 6, 0);
  lv_obj_set_style_bg_color(btn_plus, COLOR_CARD_BG2, 0);
  lv_obj_set_style_border_width(btn_plus, 1, 0);
  lv_obj_set_style_border_color(btn_plus, COLOR_TEXT_DIM, 0);
  lv_obj_align(btn_plus, LV_ALIGN_RIGHT_MID, 0, 0);
  lv_obj_t *plus_lbl = lv_label_create(btn_plus);
  lv_label_set_text(plus_lbl, "+");
  lv_obj_set_style_text_color(plus_lbl, COLOR_TEXT_PRIMARY, 0);
  lv_obj_center(plus_lbl);
  lv_obj_add_event_cb(btn_plus, interval_btn_cb, LV_EVENT_CLICKED,
                       (void *)(intptr_t)5);

  create_section_spacer(content, 4);

  /* --- SOS toggle --- */

  create_switch_row(content, "SOS Alert", ctx->settings.sos_enabled,
                     &g_sos_switch, 0);

  /* --- Fall detection toggle --- */

  create_switch_row(content, "Fall Detect", ctx->settings.fall_detect,
                     &g_fall_switch, 1);

  /* --- Simulated data toggle --- */

  create_switch_row(content, "Sim Data", ctx->settings.use_sim_data,
                     &g_sim_switch, 2);

  create_section_spacer(content, 4);

  /* --- Upload Mode --- */

  lv_obj_t *mode_label = lv_label_create(content);
  lv_label_set_text(mode_label, "Upload Mode");
  lv_obj_set_style_text_color(mode_label, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(mode_label, &lv_font_montserrat_14, 0);

  lv_obj_t *mode_row = lv_obj_create(content);
  lv_obj_set_size(mode_row, CONTENT_WIDTH, 36);
  lv_obj_set_style_bg_opa(mode_row, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(mode_row, 0, 0);
  lv_obj_set_style_pad_all(mode_row, 0, 0);
  lv_obj_remove_flag(mode_row, LV_OBJ_FLAG_SCROLLABLE);

  g_btn_mqtt = lv_button_create(mode_row);
  lv_obj_set_size(g_btn_mqtt, CONTENT_WIDTH / 2 - 4, 32);
  lv_obj_set_style_radius(g_btn_mqtt, 8, 0);
  lv_obj_set_style_bg_color(g_btn_mqtt, COLOR_CARD_BG2, 0);
  lv_obj_set_style_border_width(g_btn_mqtt, 2, 0);
  lv_obj_align(g_btn_mqtt, LV_ALIGN_LEFT_MID, 0, 0);
  lv_obj_t *mqtt_lbl = lv_label_create(g_btn_mqtt);
  lv_label_set_text(mqtt_lbl, "MQTT");
  lv_obj_set_style_text_font(mqtt_lbl, &lv_font_montserrat_14, 0);
  lv_obj_center(mqtt_lbl);
  lv_obj_add_event_cb(g_btn_mqtt, upload_mode_cb, LV_EVENT_CLICKED,
                       (void *)(intptr_t) true);

  g_btn_http = lv_button_create(mode_row);
  lv_obj_set_size(g_btn_http, CONTENT_WIDTH / 2 - 4, 32);
  lv_obj_set_style_radius(g_btn_http, 8, 0);
  lv_obj_set_style_bg_color(g_btn_http, COLOR_CARD_BG2, 0);
  lv_obj_set_style_border_width(g_btn_http, 2, 0);
  lv_obj_align(g_btn_http, LV_ALIGN_RIGHT_MID, 0, 0);
  lv_obj_t *http_lbl = lv_label_create(g_btn_http);
  lv_label_set_text(http_lbl, "HTTP");
  lv_obj_set_style_text_font(http_lbl, &lv_font_montserrat_14, 0);
  lv_obj_center(http_lbl);
  lv_obj_add_event_cb(g_btn_http, upload_mode_cb, LV_EVENT_CLICKED,
                       (void *)(intptr_t) false);

  /* Set initial upload mode state */

  if (ctx->settings.use_mqtt)
    {
      lv_obj_set_style_border_color(g_btn_mqtt, COLOR_BLUE, 0);
      lv_obj_set_style_text_color(mqtt_lbl, COLOR_TEXT_PRIMARY, 0);
      lv_obj_set_style_border_color(g_btn_http, COLOR_BORDER, 0);
      lv_obj_set_style_text_color(http_lbl, COLOR_TEXT_DIM, 0);
    }
  else
    {
      lv_obj_set_style_border_color(g_btn_http, COLOR_BLUE, 0);
      lv_obj_set_style_text_color(http_lbl, COLOR_TEXT_PRIMARY, 0);
      lv_obj_set_style_border_color(g_btn_mqtt, COLOR_BORDER, 0);
      lv_obj_set_style_text_color(mqtt_lbl, COLOR_TEXT_DIM, 0);
    }

  create_section_spacer(content, 4);

  /* Connection status */

  g_conn_status_label = lv_label_create(content);
  lv_label_set_text(g_conn_status_label, "HTTP Connected");
  lv_obj_set_style_text_color(g_conn_status_label, COLOR_GREEN, 0);
  lv_obj_set_style_text_font(g_conn_status_label, &lv_font_montserrat_14, 0);
  lv_obj_set_style_text_align(g_conn_status_label, LV_TEXT_ALIGN_CENTER, 0);

  create_section_spacer(content, 8);

  /* Save button */

  lv_obj_t *save_btn = lv_button_create(content);
  lv_obj_set_size(save_btn, CONTENT_WIDTH, 44);
  lv_obj_set_style_radius(save_btn, 22, 0);
  lv_obj_set_style_bg_color(save_btn, COLOR_BLUE, 0);
  lv_obj_set_style_bg_color(save_btn, COLOR_BLUE_DARK, LV_STATE_PRESSED);
  lv_obj_t *save_lbl = lv_label_create(save_btn);
  lv_label_set_text(save_lbl, "Save");
  lv_obj_set_style_text_color(save_lbl, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(save_lbl, &lv_font_montserrat_14, 0);
  lv_obj_center(save_lbl);
  lv_obj_add_event_cb(save_btn, save_btn_cb, LV_EVENT_CLICKED, NULL);

  return page;
}

void ui_settings_sync_controls(void)
{
  app_context_t *ctx = app_get_context();
  char buf[16];

  /* Sync brightness slider */

  lv_slider_set_value(g_brightness_slider, ctx->settings.brightness,
                       LV_ANIM_OFF);

  /* Sync interval label */

  snprintf(buf, sizeof(buf), "%lds", (long)ctx->settings.collect_interval);
  lv_label_set_text(g_interval_label, buf);

  /* Sync switches */

  if (ctx->settings.sos_enabled)
    {
      lv_obj_add_state(g_sos_switch, LV_STATE_CHECKED);
    }
  else
    {
      lv_obj_remove_state(g_sos_switch, LV_STATE_CHECKED);
    }

  if (ctx->settings.fall_detect)
    {
      lv_obj_add_state(g_fall_switch, LV_STATE_CHECKED);
    }
  else
    {
      lv_obj_remove_state(g_fall_switch, LV_STATE_CHECKED);
    }

  if (ctx->settings.use_sim_data)
    {
      lv_obj_add_state(g_sim_switch, LV_STATE_CHECKED);
    }
  else
    {
      lv_obj_remove_state(g_sim_switch, LV_STATE_CHECKED);
    }
}
