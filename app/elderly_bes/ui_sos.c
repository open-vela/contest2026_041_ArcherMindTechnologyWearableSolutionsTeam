/****************************************************************************
 * apps/examples/elderly/ui_sos.c
 *
 * SOS/Alarm page: countdown timer, vital signs snapshot, location,
 * cancel alarm button, and notification status.
 * Adapted for 454x454 circular display.
 ****************************************************************************/

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include "ui_sos.h"
#include "ui_manager.h"
#include "data_collector.h"
#include "sensor_manager.h"
#include <stdio.h>

/****************************************************************************
 * Private Data
 ****************************************************************************/

static lv_obj_t *g_alarm_title;
static lv_obj_t *g_countdown_label;
static lv_obj_t *g_countdown_desc;
static lv_obj_t *g_hr_val;
static lv_obj_t *g_spo2_val;
static lv_obj_t *g_temp_val;
static lv_obj_t *g_location_label;
static lv_obj_t *g_cancel_btn;
static lv_obj_t *g_notify_label;
static lv_timer_t *g_countdown_timer;

/****************************************************************************
 * Private Functions
 ****************************************************************************/

/**
 * Countdown timer callback (called every second).
 */

static void countdown_timer_cb(lv_timer_t *timer)
{
  LV_UNUSED(timer);
  app_context_t *ctx = app_get_context();

  if (!ctx->alarm.active)
    {
      return;
    }

  ctx->alarm.countdown--;

  if (ctx->alarm.countdown <= 0)
    {
      /* Alarm timeout - send alarm to server */

      ctx->alarm.countdown = 0;
      lv_label_set_text(g_countdown_label, "0");

      /* Notify that alarm has been sent */

      lv_label_set_text(g_notify_label,
                         "Family notified");
      lv_obj_set_style_text_color(g_notify_label, COLOR_GREEN, 0);

      /* Stop countdown timer */

      lv_timer_pause(g_countdown_timer);
    }
  else
    {
      char buf[16];
      snprintf(buf, sizeof(buf), "%ld", (long)ctx->alarm.countdown);
      lv_label_set_text(g_countdown_label, buf);
    }
}

/**
 * Cancel button event handler.
 */

static void cancel_btn_cb(lv_event_t *e)
{
  LV_UNUSED(e);
  ui_sos_cancel();
}

/**
 * Update the vital signs snapshot display.
 */

static void update_vital_snapshot(void)
{
  app_context_t *ctx = app_get_context();
  char buf[16];

  snprintf(buf, sizeof(buf), "%ld", (long)ctx->alarm.snapshot.heart_rate);
  lv_label_set_text(g_hr_val, buf);

  snprintf(buf, sizeof(buf), "%ld", (long)ctx->alarm.snapshot.spo2);
  lv_label_set_text(g_spo2_val, buf);

  snprintf(buf, sizeof(buf), "%.1f", ctx->alarm.snapshot.temperature);
  lv_label_set_text(g_temp_val, buf);
}

/**
 * Create a vital sign display box for the SOS page.
 */

static lv_obj_t *create_sos_vital_box(lv_obj_t *parent, const char *title,
                                        lv_obj_t **val_label)
{
  int box_w = (CONTENT_WIDTH - 12) / 3;

  lv_obj_t *box = lv_obj_create(parent);
  lv_obj_set_size(box, box_w, 55);
  lv_obj_set_style_bg_color(box, COLOR_CARD_BG, 0);
  lv_obj_set_style_bg_opa(box, LV_OPA_COVER, 0);
  lv_obj_set_style_radius(box, 10, 0);
  lv_obj_set_style_border_width(box, 0, 0);
  lv_obj_set_style_pad_all(box, 4, 0);
  lv_obj_remove_flag(box, LV_OBJ_FLAG_SCROLLABLE);

  /* Title */

  lv_obj_t *title_lbl = lv_label_create(box);
  lv_label_set_text(title_lbl, title);
  lv_obj_set_style_text_color(title_lbl, COLOR_TEXT_SECONDARY, 0);
  lv_obj_set_style_text_font(title_lbl, &lv_font_montserrat_14, 0);
  lv_obj_align(title_lbl, LV_ALIGN_TOP_MID, 0, 0);

  /* Value */

  *val_label = lv_label_create(box);
  lv_label_set_text(*val_label, "--");
  lv_obj_set_style_text_color(*val_label, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(*val_label, &lv_font_montserrat_24, 0);
  lv_obj_align(*val_label, LV_ALIGN_BOTTOM_MID, 0, 0);

  return box;
}

/****************************************************************************
 * Public Functions
 ****************************************************************************/

lv_obj_t *ui_sos_create(lv_obj_t *parent)
{
  lv_obj_t *page = lv_obj_create(parent);
  lv_obj_set_size(page, SCREEN_WIDTH, SCREEN_HEIGHT);
  lv_obj_set_style_bg_opa(page, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(page, 0, 0);
  lv_obj_set_style_pad_all(page, 0, 0);
  lv_obj_remove_flag(page, LV_OBJ_FLAG_SCROLLABLE);

  int top_y = SAFE_MARGIN + 5;

  /* Alarm title */

  g_alarm_title = lv_label_create(page);
  lv_label_set_text(g_alarm_title, "ALARM TRIGGERED");
  lv_obj_set_style_text_color(g_alarm_title, COLOR_RED, 0);
  lv_obj_set_style_text_font(g_alarm_title, &lv_font_montserrat_20, 0);
  lv_obj_align(g_alarm_title, LV_ALIGN_TOP_MID, 0, top_y);

  /* Countdown number */

  g_countdown_label = lv_label_create(page);
  lv_label_set_text(g_countdown_label, "10");
  lv_obj_set_style_text_color(g_countdown_label, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(g_countdown_label, &lv_font_montserrat_36, 0);
  lv_obj_align(g_countdown_label, LV_ALIGN_TOP_MID, 0, top_y + 25);

  /* Countdown description */

  g_countdown_desc = lv_label_create(page);
  lv_label_set_text(g_countdown_desc, "Auto-send in seconds");
  lv_obj_set_style_text_color(g_countdown_desc, COLOR_TEXT_SECONDARY, 0);
  lv_obj_set_style_text_font(g_countdown_desc, &lv_font_montserrat_14, 0);
  lv_obj_align(g_countdown_desc, LV_ALIGN_TOP_MID, 0, top_y + 70);

  /* Vital signs row */

  lv_obj_t *vital_row = lv_obj_create(page);
  lv_obj_set_size(vital_row, CONTENT_WIDTH, 60);
  lv_obj_align(vital_row, LV_ALIGN_TOP_MID, 0, top_y + 95);
  lv_obj_set_style_bg_opa(vital_row, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(vital_row, 0, 0);
  lv_obj_set_style_pad_all(vital_row, 0, 0);
  lv_obj_set_flex_flow(vital_row, LV_FLEX_FLOW_ROW);
  lv_obj_set_flex_align(vital_row, LV_FLEX_ALIGN_SPACE_EVENLY,
                         LV_FLEX_ALIGN_START, LV_FLEX_ALIGN_START);
  lv_obj_remove_flag(vital_row, LV_OBJ_FLAG_SCROLLABLE);

  create_sos_vital_box(vital_row, "HR", &g_hr_val);
  create_sos_vital_box(vital_row, "SpO2", &g_spo2_val);
  create_sos_vital_box(vital_row, "Temp", &g_temp_val);

  /* Location bar */

  lv_obj_t *loc_bar = lv_obj_create(page);
  lv_obj_set_size(loc_bar, CONTENT_WIDTH, 32);
  lv_obj_align(loc_bar, LV_ALIGN_TOP_MID, 0, top_y + 165);
  lv_obj_set_style_bg_color(loc_bar, COLOR_CARD_BG, 0);
  lv_obj_set_style_bg_opa(loc_bar, LV_OPA_COVER, 0);
  lv_obj_set_style_radius(loc_bar, 8, 0);
  lv_obj_set_style_border_width(loc_bar, 0, 0);
  lv_obj_set_style_pad_hor(loc_bar, 8, 0);
  lv_obj_remove_flag(loc_bar, LV_OBJ_FLAG_SCROLLABLE);

  /* Location dot indicator */

  lv_obj_t *loc_dot = lv_obj_create(loc_bar);
  lv_obj_set_size(loc_dot, 8, 8);
  lv_obj_set_style_radius(loc_dot, 4, 0);
  lv_obj_set_style_bg_color(loc_dot, COLOR_BLUE, 0);
  lv_obj_set_style_border_width(loc_dot, 0, 0);
  lv_obj_align(loc_dot, LV_ALIGN_LEFT_MID, 0, 0);

  g_location_label = lv_label_create(loc_bar);
  lv_label_set_text(g_location_label, "Location: Acquiring...");
  lv_obj_set_style_text_color(g_location_label, COLOR_TEXT_SECONDARY, 0);
  lv_obj_set_style_text_font(g_location_label, &lv_font_montserrat_14, 0);
  lv_obj_align(g_location_label, LV_ALIGN_LEFT_MID, 14, 0);

  /* Cancel alarm button */

  g_cancel_btn = lv_button_create(page);
  lv_obj_set_size(g_cancel_btn, 200, 44);
  lv_obj_align(g_cancel_btn, LV_ALIGN_TOP_MID, 0, top_y + 210);
  lv_obj_set_style_radius(g_cancel_btn, 22, 0);
  lv_obj_set_style_bg_color(g_cancel_btn, COLOR_CARD_BG2, 0);
  lv_obj_set_style_bg_color(g_cancel_btn, COLOR_CARD_BG, LV_STATE_PRESSED);
  lv_obj_set_style_border_width(g_cancel_btn, 1, 0);
  lv_obj_set_style_border_color(g_cancel_btn, COLOR_TEXT_DIM, 0);
  lv_obj_t *cancel_lbl = lv_label_create(g_cancel_btn);
  lv_label_set_text(cancel_lbl, "Cancel Alarm");
  lv_obj_set_style_text_color(cancel_lbl, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(cancel_lbl, &lv_font_montserrat_14, 0);
  lv_obj_center(cancel_lbl);
  lv_obj_add_event_cb(g_cancel_btn, cancel_btn_cb, LV_EVENT_CLICKED, NULL);

  /* Notification status */

  g_notify_label = lv_label_create(page);
  lv_label_set_text(g_notify_label, "Awaiting...");
  lv_obj_set_style_text_color(g_notify_label, COLOR_TEXT_DIM, 0);
  lv_obj_set_style_text_font(g_notify_label, &lv_font_montserrat_14, 0);
  lv_obj_set_style_text_align(g_notify_label, LV_TEXT_ALIGN_CENTER, 0);
  lv_obj_align(g_notify_label, LV_ALIGN_BOTTOM_MID, 0, -SAFE_MARGIN);

  /* Create countdown timer (paused initially) */

  g_countdown_timer = lv_timer_create(countdown_timer_cb, 1000, NULL);
  lv_timer_pause(g_countdown_timer);

  /* Hide page initially */

  lv_obj_add_flag(page, LV_OBJ_FLAG_HIDDEN);

  return page;
}

void ui_sos_activate(const char *alarm_type)
{
  app_context_t *ctx = app_get_context();

  /* Set alarm state */

  ctx->alarm.active = true;
  ctx->alarm.countdown = SOS_COUNTDOWN_SEC;
  strncpy(ctx->alarm.alarm_type, alarm_type,
          sizeof(ctx->alarm.alarm_type) - 1);

  /* Snapshot current vital signs */

  memcpy(&ctx->alarm.snapshot, &ctx->vitals, sizeof(vital_data_t));

  /* Update UI */

  char buf[16];
  snprintf(buf, sizeof(buf), "%d", SOS_COUNTDOWN_SEC);
  lv_label_set_text(g_countdown_label, buf);

  /* Show alarm type in title */

  if (strcmp(alarm_type, "FALL") == 0)
    {
      lv_label_set_text(g_alarm_title, "FALL DETECTED!");
    }
  else
    {
      lv_label_set_text(g_alarm_title, "SOS ALARM");
    }

  /* Set location */

  if (strlen(ctx->alarm.location) > 0)
    {
      char loc_buf[140];
      snprintf(loc_buf, sizeof(loc_buf), "Loc: %s", ctx->alarm.location);
      lv_label_set_text(g_location_label, loc_buf);
    }
  else
    {
      lv_label_set_text(g_location_label, "Loc: Acquiring...");
    }

  /* Update vital snapshot */

  update_vital_snapshot();

  /* Reset notification label */

  lv_label_set_text(g_notify_label, "Awaiting...");
  lv_obj_set_style_text_color(g_notify_label, COLOR_TEXT_DIM, 0);

  /* Show the SOS page */

  ui_manager_switch_page(PAGE_SOS);

  /* Start countdown */

  lv_timer_resume(g_countdown_timer);
}

void ui_sos_cancel(void)
{
  app_context_t *ctx = app_get_context();

  ctx->alarm.active = false;
  ctx->alarm.countdown = 0;

  /* Stop countdown */

  lv_timer_pause(g_countdown_timer);

  /* Update notification */

  lv_label_set_text(g_notify_label, "Alarm cancelled");
  lv_obj_set_style_text_color(g_notify_label, COLOR_YELLOW, 0);

  /* Return to index page */

  ui_manager_switch_page(PAGE_INDEX);
}

void ui_sos_update_countdown(void)
{
  app_context_t *ctx = app_get_context();
  char buf[16];
  snprintf(buf, sizeof(buf), "%ld", (long)ctx->alarm.countdown);
  lv_label_set_text(g_countdown_label, buf);
  update_vital_snapshot();
}

bool ui_sos_is_active(void)
{
  return app_get_context()->alarm.active;
}
