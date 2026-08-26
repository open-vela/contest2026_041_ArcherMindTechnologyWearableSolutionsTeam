/****************************************************************************
 * apps/examples/elderly/ui_index.c
 *
 * Home/Index page: SOS button, vital signs cards, step progress.
 * Adapted for 454x454 circular AMOLED display (BES2800).
 *
 * Layout (top to bottom, centered for round screen):
 *   - Status bar (HTTP connection, battery)
 *   - Large red SOS button with "Hold for SOS"
 *   - Three vital sign cards (heart rate, SpO2, temperature)
 *   - Step progress bar
 *   - Health status message
 ****************************************************************************/

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include "ui_index.h"
#include "ui_manager.h"
#include "sensor_manager.h"
#include "data_collector.h"

/****************************************************************************
 * Pre-processor Definitions
 ****************************************************************************/

/* Layout constants for 454x454 circular display */

#define SOS_BTN_SIZE        120
#define VITAL_CARD_W        95
#define VITAL_CARD_H        65

/****************************************************************************
 * Private Data
 ****************************************************************************/

static lv_obj_t *g_hr_label;
static lv_obj_t *g_spo2_label;
static lv_obj_t *g_temp_label;
static lv_obj_t *g_steps_label;
static lv_obj_t *g_steps_bar;
static lv_obj_t *g_status_label;
static lv_obj_t *g_status_bar;
static lv_obj_t *g_battery_label;
static lv_obj_t *g_conn_label;
static lv_obj_t *g_posture_label;

static lv_obj_t *g_hr_dot;
static lv_obj_t *g_spo2_dot;
static lv_obj_t *g_temp_dot;

/****************************************************************************
 * Private Functions
 ****************************************************************************/

/**
 * Create the status bar at the top showing connection and battery.
 */

static lv_obj_t *create_status_bar(lv_obj_t *parent)
{
  lv_obj_t *bar = lv_obj_create(parent);
  lv_obj_set_size(bar, 200, 28);
  lv_obj_align(bar, LV_ALIGN_TOP_MID, 0, SAFE_MARGIN);
  lv_obj_set_style_bg_opa(bar, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(bar, 0, 0);
  lv_obj_set_style_pad_all(bar, 0, 0);
  lv_obj_remove_flag(bar, LV_OBJ_FLAG_SCROLLABLE);

  /* Connection status */

  g_conn_label = lv_label_create(bar);
  lv_label_set_text(g_conn_label, LV_SYMBOL_WIFI " HTTP");
  lv_obj_set_style_text_color(g_conn_label, COLOR_GREEN, 0);
  lv_obj_set_style_text_font(g_conn_label, &lv_font_montserrat_14, 0);
  lv_obj_align(g_conn_label, LV_ALIGN_LEFT_MID, 0, 0);

  /* Battery */

  g_battery_label = lv_label_create(bar);
  lv_label_set_text(g_battery_label, LV_SYMBOL_BATTERY_FULL " 85%");
  lv_obj_set_style_text_color(g_battery_label, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(g_battery_label, &lv_font_montserrat_14, 0);
  lv_obj_align(g_battery_label, LV_ALIGN_RIGHT_MID, 0, 0);

  return bar;
}

/**
 * SOS button long press event handler.
 */

static void sos_btn_press_cb(lv_event_t *e)
{
  lv_event_code_t code = lv_event_get_code(e);

  if (code == LV_EVENT_LONG_PRESSED || code == LV_EVENT_CLICKED)
    {
      data_collector_trigger_sos();
    }
}

/**
 * Create the central SOS button.
 */

static lv_obj_t *create_sos_button(lv_obj_t *parent)
{
  /* Container for centering */

  lv_obj_t *cont = lv_obj_create(parent);
  lv_obj_set_size(cont, SOS_BTN_SIZE + 20, SOS_BTN_SIZE + 20);
  lv_obj_align(cont, LV_ALIGN_CENTER, 0, -60);
  lv_obj_set_style_bg_opa(cont, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(cont, 0, 0);
  lv_obj_set_style_pad_all(cont, 0, 0);
  lv_obj_remove_flag(cont, LV_OBJ_FLAG_SCROLLABLE);

  /* Red circle button */

  lv_obj_t *btn = lv_button_create(cont);
  lv_obj_set_size(btn, SOS_BTN_SIZE, SOS_BTN_SIZE);
  lv_obj_center(btn);
  lv_obj_set_style_radius(btn, SOS_BTN_SIZE / 2, 0);
  lv_obj_set_style_bg_color(btn, COLOR_RED, 0);
  lv_obj_set_style_bg_color(btn, COLOR_RED_DARK, LV_STATE_PRESSED);
  lv_obj_set_style_shadow_width(btn, 20, 0);
  lv_obj_set_style_shadow_color(btn, COLOR_RED, 0);
  lv_obj_set_style_shadow_opa(btn, LV_OPA_30, 0);
  lv_obj_add_flag(btn, LV_OBJ_FLAG_CLICKABLE);

  /* SOS text */

  lv_obj_t *sos_text = lv_label_create(btn);
  lv_label_set_text(sos_text, "SOS");
  lv_obj_set_style_text_color(sos_text, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(sos_text, &lv_font_montserrat_28, 0);
  lv_obj_align(sos_text, LV_ALIGN_CENTER, 0, -8);

  /* Instruction text */

  lv_obj_t *inst_text = lv_label_create(btn);
  lv_label_set_text(inst_text, "Hold for SOS");
  lv_obj_set_style_text_color(inst_text, lv_color_hex(0xFFCCCC), 0);
  lv_obj_set_style_text_font(inst_text, &lv_font_montserrat_14, 0);
  lv_obj_align(inst_text, LV_ALIGN_CENTER, 0, 16);

  /* Press and click events */

  lv_obj_add_event_cb(btn, sos_btn_press_cb, LV_EVENT_LONG_PRESSED, NULL);
  lv_obj_add_event_cb(btn, sos_btn_press_cb, LV_EVENT_CLICKED, NULL);

  return cont;
}

/**
 * Create a single vital sign card.
 */

static lv_obj_t *create_vital_card(lv_obj_t *parent, const char *title,
                                    const char *unit, lv_obj_t **value_label,
                                    lv_obj_t **dot_indicator)
{
  lv_obj_t *card = lv_obj_create(parent);
  lv_obj_set_size(card, VITAL_CARD_W, VITAL_CARD_H);
  lv_obj_set_style_bg_color(card, COLOR_CARD_BG, 0);
  lv_obj_set_style_bg_opa(card, LV_OPA_COVER, 0);
  lv_obj_set_style_radius(card, 12, 0);
  lv_obj_set_style_border_width(card, 0, 0);
  lv_obj_set_style_pad_all(card, 4, 0);
  lv_obj_remove_flag(card, LV_OBJ_FLAG_SCROLLABLE);

  /* Status dot */

  *dot_indicator = lv_obj_create(card);
  lv_obj_set_size(*dot_indicator, 8, 8);
  lv_obj_align(*dot_indicator, LV_ALIGN_TOP_LEFT, 2, 2);
  lv_obj_set_style_radius(*dot_indicator, 4, 0);
  lv_obj_set_style_bg_color(*dot_indicator, COLOR_GREEN, 0);
  lv_obj_set_style_border_width(*dot_indicator, 0, 0);

  /* Title label */

  lv_obj_t *title_lbl = lv_label_create(card);
  lv_label_set_text(title_lbl, title);
  lv_obj_set_style_text_color(title_lbl, COLOR_TEXT_SECONDARY, 0);
  lv_obj_set_style_text_font(title_lbl, &lv_font_montserrat_14, 0);
  lv_obj_align(title_lbl, LV_ALIGN_TOP_MID, 0, 2);

  /* Value label */

  *value_label = lv_label_create(card);
  lv_label_set_text(*value_label, "--");
  lv_obj_set_style_text_color(*value_label, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(*value_label, &lv_font_montserrat_24, 0);
  lv_obj_align(*value_label, LV_ALIGN_CENTER, 0, 4);

  /* Unit label */

  lv_obj_t *unit_lbl = lv_label_create(card);
  lv_label_set_text(unit_lbl, unit);
  lv_obj_set_style_text_color(unit_lbl, COLOR_TEXT_DIM, 0);
  lv_obj_set_style_text_font(unit_lbl, &lv_font_montserrat_14, 0);
  lv_obj_align(unit_lbl, LV_ALIGN_BOTTOM_MID, 0, -2);

  return card;
}

/**
 * Create the three vital sign cards in a row.
 */

static lv_obj_t *create_vital_cards_row(lv_obj_t *parent)
{
  lv_obj_t *cont = lv_obj_create(parent);
  lv_obj_set_size(cont, SCREEN_WIDTH - 2 * SAFE_MARGIN + 10, VITAL_CARD_H + 4);
  lv_obj_set_style_bg_opa(cont, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(cont, 0, 0);
  lv_obj_set_style_pad_all(cont, 0, 0);
  lv_obj_set_flex_flow(cont, LV_FLEX_FLOW_ROW);
  lv_obj_set_flex_align(cont, LV_FLEX_ALIGN_SPACE_EVENLY,
                         LV_FLEX_ALIGN_START, LV_FLEX_ALIGN_START);
  lv_obj_remove_flag(cont, LV_OBJ_FLAG_SCROLLABLE);

  create_vital_card(cont, "HR", "bpm", &g_hr_label, &g_hr_dot);
  create_vital_card(cont, "SpO2", "%", &g_spo2_label, &g_spo2_dot);
  create_vital_card(cont, "Temp", "\xc2\xb0""C", &g_temp_label, &g_temp_dot);

  return cont;
}

/**
 * Create the step progress section.
 */

static lv_obj_t *create_step_section(lv_obj_t *parent)
{
  lv_obj_t *cont = lv_obj_create(parent);
  int w = SCREEN_WIDTH - 2 * SAFE_MARGIN + 10;
  lv_obj_set_size(cont, w, 50);
  lv_obj_set_style_bg_opa(cont, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(cont, 0, 0);
  lv_obj_set_style_pad_all(cont, 0, 0);
  lv_obj_remove_flag(cont, LV_OBJ_FLAG_SCROLLABLE);

  /* Activity label */

  lv_obj_t *act_label = lv_label_create(cont);
  lv_label_set_text(act_label, "Activity");
  lv_obj_set_style_text_color(act_label, COLOR_TEXT_SECONDARY, 0);
  lv_obj_set_style_text_font(act_label, &lv_font_montserrat_14, 0);
  lv_obj_align(act_label, LV_ALIGN_TOP_LEFT, 0, 0);

  /* Posture label (姿态) */

  g_posture_label = lv_label_create(cont);
  lv_label_set_text(g_posture_label, LV_SYMBOL_HOME " Standing");
  lv_obj_set_style_text_color(g_posture_label, COLOR_BLUE, 0);
  lv_obj_set_style_text_font(g_posture_label, &lv_font_montserrat_14, 0);
  lv_obj_align(g_posture_label, LV_ALIGN_TOP_MID, 0, 0);

  /* Step count label */

  g_steps_label = lv_label_create(cont);
  lv_label_set_text(g_steps_label, "0 / 6000 steps");
  lv_obj_set_style_text_color(g_steps_label, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(g_steps_label, &lv_font_montserrat_14, 0);
  lv_obj_align(g_steps_label, LV_ALIGN_TOP_RIGHT, 0, 0);

  /* Progress bar */

  g_steps_bar = lv_bar_create(cont);
  lv_obj_set_size(g_steps_bar, w, 12);
  lv_obj_align(g_steps_bar, LV_ALIGN_BOTTOM_MID, 0, 0);
  lv_bar_set_range(g_steps_bar, 0, DAILY_STEPS_GOAL);
  lv_bar_set_value(g_steps_bar, 0, LV_ANIM_ON);
  lv_obj_set_style_radius(g_steps_bar, 6, 0);
  lv_obj_set_style_radius(g_steps_bar, 6, LV_PART_INDICATOR);
  lv_obj_set_style_bg_color(g_steps_bar, COLOR_PROGRESS_BG, 0);
  lv_obj_set_style_bg_color(g_steps_bar, COLOR_BLUE, LV_PART_INDICATOR);

  return cont;
}

/**
 * Create the health status message bar at the bottom.
 */

static lv_obj_t *create_health_status_bar(lv_obj_t *parent)
{
  g_status_bar = lv_obj_create(parent);
  lv_obj_set_size(g_status_bar, 220, 32);
  lv_obj_set_style_bg_color(g_status_bar, COLOR_CARD_BG, 0);
  lv_obj_set_style_bg_opa(g_status_bar, LV_OPA_COVER, 0);
  lv_obj_set_style_radius(g_status_bar, 16, 0);
  lv_obj_set_style_border_width(g_status_bar, 0, 0);
  lv_obj_set_style_pad_all(g_status_bar, 0, 0);
  lv_obj_remove_flag(g_status_bar, LV_OBJ_FLAG_SCROLLABLE);

  g_status_label = lv_label_create(g_status_bar);
  lv_label_set_text(g_status_label, LV_SYMBOL_OK " All vitals normal");
  lv_obj_set_style_text_color(g_status_label, COLOR_GREEN, 0);
  lv_obj_set_style_text_font(g_status_label, &lv_font_montserrat_14, 0);
  lv_obj_center(g_status_label);

  return g_status_bar;
}

/****************************************************************************
 * Public Functions
 ****************************************************************************/

lv_obj_t *ui_index_create(lv_obj_t *parent)
{
  lv_obj_t *page = lv_obj_create(parent);
  lv_obj_set_size(page, SCREEN_WIDTH, SCREEN_HEIGHT);
  lv_obj_set_style_bg_opa(page, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(page, 0, 0);
  lv_obj_set_style_pad_all(page, 0, 0);
  lv_obj_remove_flag(page, LV_OBJ_FLAG_SCROLLABLE);

  /* Layout: status bar, SOS, vitals, steps, health status */

  create_status_bar(page);
  create_sos_button(page);
  create_vital_cards_row(page);
  create_step_section(page);
  create_health_status_bar(page);

  /* Position the vital cards below the SOS button */

  lv_obj_t *cards = lv_obj_get_child(page, 2);
  lv_obj_align(cards, LV_ALIGN_CENTER, 0, 45);

  /* Position the step section below vitals */

  lv_obj_t *steps = lv_obj_get_child(page, 3);
  lv_obj_align(steps, LV_ALIGN_CENTER, 0, 95);

  /* Position health status at bottom (inside circular boundary) */

  lv_obj_align(g_status_bar, LV_ALIGN_BOTTOM_MID, 0, -SAFE_MARGIN);

  return page;
}

void ui_index_update_vitals(void)
{
  app_context_t *ctx = app_get_context();
  char buf[32];

  /* Heart rate */

  snprintf(buf, sizeof(buf), "%ld", (long)ctx->vitals.heart_rate);
  lv_label_set_text(g_hr_label, buf);
  lv_obj_set_style_text_color(g_hr_label,
                               get_hr_status_color(ctx->vitals.heart_rate), 0);
  lv_obj_set_style_bg_color(g_hr_dot,
                             get_hr_status_color(ctx->vitals.heart_rate), 0);

  /* SpO2 */

  snprintf(buf, sizeof(buf), "%ld", (long)ctx->vitals.spo2);
  lv_label_set_text(g_spo2_label, buf);
  lv_obj_set_style_bg_color(g_spo2_dot,
                             get_spo2_status_color(ctx->vitals.spo2), 0);

  /* Temperature */

  snprintf(buf, sizeof(buf), "%.1f", ctx->vitals.temperature);
  lv_label_set_text(g_temp_label, buf);
  lv_obj_set_style_bg_color(g_temp_dot,
                             get_temp_status_color(ctx->vitals.temperature), 0);

  /* Battery */

  snprintf(buf, sizeof(buf), LV_SYMBOL_BATTERY_FULL " %ld%%",
           (long)ctx->vitals.battery);
  lv_label_set_text(g_battery_label, buf);

  /* Connection status */

  if (ctx->network_connected)
    {
      lv_label_set_text(g_conn_label, LV_SYMBOL_WIFI " HTTP");
      lv_obj_set_style_text_color(g_conn_label, COLOR_GREEN, 0);
    }
  else
    {
      lv_label_set_text(g_conn_label, LV_SYMBOL_WIFI " Offline");
      lv_obj_set_style_text_color(g_conn_label, COLOR_RED, 0);
    }
}

void ui_index_update_steps(void)
{
  app_context_t *ctx = app_get_context();
  char buf[32];

  snprintf(buf, sizeof(buf), "%ld / %d steps",
           (long)ctx->vitals.steps, DAILY_STEPS_GOAL);
  lv_label_set_text(g_steps_label, buf);
  lv_bar_set_value(g_steps_bar, ctx->vitals.steps, LV_ANIM_ON);
}

void ui_index_update_health_status(void)
{
  app_context_t *ctx = app_get_context();
  const sensor_data_t *sensor = sensor_manager_get();
  bool abnormal = data_collector_check_abnormal(&ctx->vitals);

  if (sensor->fall_detected)
    {
      lv_label_set_text(g_status_label,
                         LV_SYMBOL_WARNING " FALL DETECTED!");
      lv_obj_set_style_text_color(g_status_label, COLOR_RED, 0);
    }
  else if (abnormal)
    {
      lv_label_set_text(g_status_label,
                         LV_SYMBOL_WARNING " Abnormal vitals");
      lv_obj_set_style_text_color(g_status_label, COLOR_YELLOW, 0);
    }
  else
    {
      lv_label_set_text(g_status_label,
                         LV_SYMBOL_OK " All vitals normal");
      lv_obj_set_style_text_color(g_status_label, COLOR_GREEN, 0);
    }

  /* Update posture display */

  if (g_posture_label && sensor->posture_name)
    {
      const char *icon;
      switch (sensor->posture)
        {
          case POSTURE_WALKING:   icon = LV_SYMBOL_PLAY; break;
          case POSTURE_RUNNING:   icon = LV_SYMBOL_PLAY; break;
          case POSTURE_STANDING:  icon = LV_SYMBOL_HOME; break;
          case POSTURE_SITTING:   icon = LV_SYMBOL_HOME; break;
          case POSTURE_LYING_FLAT:
          case POSTURE_LYING_SIDE: icon = LV_SYMBOL_PAUSE; break;
          default:                icon = LV_SYMBOL_REFRESH; break;
        }

      char buf[32];
      snprintf(buf, sizeof(buf), "%s %s", icon, sensor->posture_name);
      lv_label_set_text(g_posture_label, buf);
    }
}
