/****************************************************************************
 * apps/examples/elderly_bes/data_collector.c
 *
 * Stub implementation - data collection disabled for initial bring-up.
 ****************************************************************************/

#include "data_collector.h"
#include <string.h>
#include <stdlib.h>
#include <time.h>

static app_context_t g_app_ctx;

app_context_t *app_get_context(void)
{
  return &g_app_ctx;
}

void data_collector_init(void)
{
  memset(&g_app_ctx, 0, sizeof(g_app_ctx));
  g_app_ctx.settings.brightness = 80;
  g_app_ctx.settings.collect_interval = 10;
  g_app_ctx.settings.sos_enabled = true;
  g_app_ctx.settings.fall_detect = true;
  g_app_ctx.settings.use_sim_data = true;

  g_app_ctx.vitals.heart_rate = 72;
  g_app_ctx.vitals.spo2 = 97;
  g_app_ctx.vitals.temperature = 36.5f;
  g_app_ctx.vitals.steps = 0;
  g_app_ctx.vitals.battery = 85;
  g_app_ctx.vitals.device_online = true;

  g_app_ctx.network_connected = false;
}

void data_collector_stop(void)
{
}

void data_collector_trigger_sos(void)
{
}

const vital_data_t *data_collector_get_vitals(void)
{
  return &g_app_ctx.vitals;
}

bool data_collector_check_abnormal(const vital_data_t *v)
{
  if (v->heart_rate < HR_LOW || v->heart_rate > HR_HIGH)
    return true;
  if (v->spo2 < SPO2_LOW)
    return true;
  if (v->temperature < TEMP_LOW || v->temperature > TEMP_HIGH)
    return true;
  return false;
}

const char *get_hr_status(int32_t hr)
{
  if (hr >= HR_LOW && hr <= HR_HIGH) return "Normal";
  else if (hr < HR_LOW) return "Low";
  else return "High";
}

lv_color_t get_hr_status_color(int32_t hr)
{
  if (hr >= HR_LOW && hr <= HR_HIGH) return COLOR_GREEN;
  return COLOR_RED;
}

const char *get_spo2_status(int32_t spo2)
{
  if (spo2 >= SPO2_LOW) return "Normal";
  return "Low";
}

lv_color_t get_spo2_status_color(int32_t spo2)
{
  if (spo2 >= SPO2_LOW) return COLOR_GREEN;
  return COLOR_RED;
}

const char *get_temp_status(float temp)
{
  if (temp >= TEMP_LOW && temp <= TEMP_HIGH) return "Normal";
  else if (temp < TEMP_LOW) return "Low";
  else return "High";
}

lv_color_t get_temp_status_color(float temp)
{
  if (temp >= TEMP_LOW && temp <= TEMP_HIGH) return COLOR_GREEN;
  return COLOR_RED;
}

void apply_card_style(lv_obj_t *obj)
{
  lv_obj_set_style_bg_color(obj, COLOR_CARD_BG, 0);
  lv_obj_set_style_bg_opa(obj, LV_OPA_COVER, 0);
  lv_obj_set_style_radius(obj, 12, 0);
  lv_obj_set_style_border_width(obj, 0, 0);
  lv_obj_set_style_pad_all(obj, 8, 0);
}

void apply_rounded_btn_style(lv_obj_t *obj, lv_color_t bg_color)
{
  lv_obj_set_style_bg_color(obj, bg_color, 0);
  lv_obj_set_style_radius(obj, 22, 0);
  lv_obj_set_style_border_width(obj, 0, 0);
}

void create_dot_indicator(lv_obj_t *parent, lv_color_t color,
                          lv_coord_t x, lv_coord_t y)
{
  lv_obj_t *dot = lv_obj_create(parent);
  lv_obj_set_size(dot, 8, 8);
  lv_obj_set_pos(dot, x, y);
  lv_obj_set_style_radius(dot, 4, 0);
  lv_obj_set_style_bg_color(dot, color, 0);
  lv_obj_set_style_border_width(dot, 0, 0);
}
